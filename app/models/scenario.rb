class Scenario < ActiveRecord::Base

  before_save {

    dummy = 'dummy@dummy.com'

    if email == dummy
      self.primary = false
    else
      email.downcase!
      self.primary = true
    end

    # Get the area details from Broadband Map - Census.gov
    if self.primary
      Parallel.each([1, 2], in_threads: 6) { |p|
        self.get_area_details if p == 1
        self.get_closer_zips if p == 2
      }
      self.get_nearby_businesses dummy
      self.load_reviews self.zomato_restaurant_id
    end

    true
  }

  before_destroy {
    unless self.nearby_restaurants.nil?
      eval(self.nearby_restaurants).each do |current_nearby|
        Scenario.where(primary: true).each do |other|
          unless other.nearby_restaurants.include? current_nearby
            Scenario.where(zomato_restaurant_id: current_nearby).destroy_all
          end
        end
      end
    end
  }

  # Get the area details from Broadband Map - Census.gov
  def get_area_details
    response = RestClient.get "http://www.broadbandmap.gov/broadbandmap/census/block?latitude=#{self.location_lat}&longitude=#{self.location_lng}&format=json"
    if response.code == 200
      response = JSON.parse(response)
      self.fips_block_type = response['Results']['block'][0]['geographyType']
      self.fips_state = response['Results']['block'][0]['FIPS'][1..2]
      self.fips_county = response['Results']['block'][0]['FIPS'][2..4]
      self.fips_tract = response['Results']['block'][0]['FIPS'][5..10]
      true
    end
    false
  end

  # Get the nearest zip codes from zipcodeAPI
  def get_closer_zips
    response = RestClient.get "https://www.zipcodeapi.com/rest/sAuK5UYivE54AQMykjxjPkmh3BCPaMiDnNnsImLd1RiCH5a1oHle2Iw5k8VuVe8i/radius.json/#{self.zomato_postal_code}/15/mile"
    if response.code == 200
      response = JSON.parse(response)
      closer_zips = []
      closer_zips_coords = []
      nearest_distance = 10

      Parallel.each(response['zip_codes'], in_threads: 8) { |zip_code|
        # Get the coordinates of each zip from Google Geocode API
        zip_coords = RestClient.get "https://maps.googleapis.com/maps/api/geocode/json?&address=#{zip_code['zip_code']}&key=AIzaSyDyKaPV4Oq0e5wpcKwyqV-hKolT1Bqc5vs"
        zip_coords = JSON.parse(zip_coords)
        if zip_coords['status'] == 'OK'
          # Get Distance from Google Distance Maps API
          distance = RestClient.get "https://maps.googleapis.com/maps/api/distancematrix/json?origins=#{self.location_lat},#{self.location_lng}&destinations=#{zip_coords["results"][0]["geometry"]["location"]["lat"]},#{zip_coords["results"][0]["geometry"]["location"]["lng"]}&key=AIzaSyDyKaPV4Oq0e5wpcKwyqV-hKolT1Bqc5vs"
          distance = JSON.parse(distance)
          if distance['status'] == 'OK' and distance['rows'][0]['elements'][0]['status'] == 'OK'
            distance = distance['rows'][0]['elements'][0]['distance']['value']*0.000621371
            if distance <= 5 and zip_code['zip_code'] != self.zomato_postal_code
              closer_zips.push zip_code['zip_code']
              closer_zips_coords.push "#{zip_coords['results'][0]['geometry']['location']['lat']},#{zip_coords['results'][0]['geometry']['location']['lng']}"
              if nearest_distance or nearest_distance > distance
                nearest_distance = distance
                self.nearest_zip = zip_code['zip_code'];
                self.nearest_zip_coords = "#{zip_coords['results'][0]['geometry']['location']['lat']},#{zip_coords['results'][0]['geometry']['location']['lng']}"
              end
            end
          end
        end
      }
      self.closer_zips = closer_zips.to_s
      self.closer_zips_coords = closer_zips_coords.to_s
      true
    end
    false
  end

  # Get the nearest restaurants from Zomato API (Max 20 Restaurants)
  def get_nearby_businesses(email)
    nearby_restaurants = []
    response = RestClient.get "https://developers.zomato.com/api/v2.1/search?q=#{self.zomato_cuisines}&lat=#{self.location_lat}&lon=#{self.location_lng}&radius=20000", accept: :json, 'user-key' => 'f9b94c7980f30bbc41833a1a0ed843ca'
    if response.code == 200
      response = JSON.parse(response)
      response['restaurants'].each do |item|
        if item['restaurant']['id'] != self.zomato_restaurant_id.to_s
          nearby_restaurants.push item['restaurant']['id']
          secondary_rest = Scenario.new
          secondary_rest = load_scenario secondary_rest, item
          secondary_rest.email = email
          secondary_rest.save
        end
      end
      self.nearby_restaurants = nearby_restaurants.to_s
      true
    end
    false
  end

  # Load new Restaurant to Scenario from Zomato JSON (Search API)
  def load_scenario(new_scenario, item)
    new_scenario.business_name = item['restaurant']['name']
    new_scenario.zomato_restaurant_id = item['restaurant']['id']
    new_scenario.location_lat = item['restaurant']['location']['latitude']
    new_scenario.location_lng = item['restaurant']['location']['longitude']
    new_scenario.zomato_address = item['restaurant']['location']['address']
    new_scenario.zomato_loc_city_id = item['restaurant']['location']['city_id']
    new_scenario.zomato_loc_city = item['restaurant']['location']['city']
    new_scenario.zomato_postal_code = item['restaurant']['location']['zipcode']
    new_scenario.zomato_cuisines = item['restaurant']['cuisines']
    new_scenario.zomato_user_rating = item['restaurant']['user_rating']['aggregate_rating']
    new_scenario.zomato_rating_text = item['restaurant']['user_rating']['rating_text']
    new_scenario.zomato_rating_color = item['restaurant']['user_rating']['rating_color']
    new_scenario.zomato_votes_count = item['restaurant']['user_rating']['votes']
    new_scenario.zomato_has_online_delivery = item['restaurant']['has_online_delivery']
    new_scenario.zomato_price_range = item['restaurant']['price_range']
    new_scenario.zomato_average_cost_for_two = item['restaurant']['average_cost_for_two']
    new_scenario.zomato_thumb = item['restaurant']['thumb']
    new_scenario
  end

  # Get reviews from Zomato
  def load_reviews(restaurant_id)
    response = RestClient.get "https://developers.zomato.com/api/v2.1/reviews?res_id=#{restaurant_id}", accept: :json, 'user-key' => 'f9b94c7980f30bbc41833a1a0ed843ca'
    if response.code == 200
      if response && response.length >= 2
        response = JSON.parse(response)
        response['user_reviews'].each do |review|
          new_review = Review.new
          new_review.review_rating = review['review']['rating']
          new_review.review_text = review['review']['review_text']
          new_review.rating_color = review['review']['rating_color']
          new_review.rating_text = review['review']['rating_text']
          new_review.review_time_stamp = review['review']['timestamp']
          new_review.likes = review['review']['likes']
          new_review.author_name = review['review']['user']['name']
          new_review.author_foodie_level = review['review']['user']['foodie_level']
          new_review.user_image = review['review']['user']['profile_image']
          new_review.comments_count = review['review']['comments_count']
          new_review.restaurant_id = restaurant_id
          new_review.save
        end
      end
    end
  end

  validates :business_name, presence: true, length: { maximum: 100 }
  validates :location_lat, presence: true
  validates :location_lng, presence: true
  validates :zomato_restaurant_id, presence: true,
            uniqueness: { case_sensitive: false }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
            format: { with: VALID_EMAIL_REGEX }
end
