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
    end

    current_reviews = Review.where(restaurant_id: self.zomato_restaurant_id)
    if current_reviews.count == 0 || current_reviews.first.created_at < 2.weeks.ago
      current_reviews.destroy_all
      self.load_reviews
    end
    Parallel.each([1, 2], in_threads: 6) { |p|
      self.get_ranking
    }

    self.zomato_user_rating = Review.where(restaurant_id: self.zomato_restaurant_id).average(:review_rating) if self.zomato_user_rating == 0
    true
  }

  before_destroy {
    unless self.nearby_restaurants.nil?
      eval(self.nearby_restaurants).each do |current_nearby|
        other_restaurants = Scenario.where(primary: true).where.not(id: self.id)
        if other_restaurants.count != 0
          other_restaurants.each do |other|
            unless other.nearby_restaurants.include? current_nearby
              Scenario.where(zomato_restaurant_id: current_nearby).first.destroy
            end
          end
        else
          Scenario.where(zomato_restaurant_id: current_nearby).first.destroy
        end
      end
    end
    Review.where(restaurant_id: self.zomato_restaurant_id).destroy_all
    true
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
    response = RestClient.get "https://www.zipcodeapi.com/rest/#{Rails.application.config.zip_code_key}/radius.json/#{self.zomato_postal_code}/15/mile"
    if response.code == 200
      response = JSON.parse(response)
      closer_zips = []
      closer_zips_coords = []
      nearest_distance = 10

      Parallel.each(response['zip_codes'], in_threads: 8) { |zip_code|
        # Get the coordinates of each zip from Google Geocode API
        zip_coords = RestClient.get "https://maps.googleapis.com/maps/api/geocode/json?&address=#{zip_code['zip_code']}&key=#{Rails.application.config.google_key}"
        zip_coords = JSON.parse(zip_coords)
        if zip_coords['status'] == 'OK'
          # Get Distance from Google Distance Maps API
          distance = RestClient.get "https://maps.googleapis.com/maps/api/distancematrix/json?origins=#{self.location_lat},#{self.location_lng}&destinations=#{zip_coords["results"][0]["geometry"]["location"]["lat"]},#{zip_coords["results"][0]["geometry"]["location"]["lng"]}&key=#{Rails.application.config.google_key}"
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
    response = RestClient.get "https://developers.zomato.com/api/v2.1/search?q=#{self.zomato_cuisines}&lat=#{self.location_lat}&lon=#{self.location_lng}&radius=20000", accept: :json, 'user-key' => Rails.application.config.zomato_key
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
  def load_reviews
    response = RestClient.get "https://developers.zomato.com/api/v2.1/reviews?res_id=#{self.zomato_restaurant_id}", accept: :json, 'user-key' => Rails.application.config.zomato_key
    if response.code == 200
      if response && response.length >= 2
        response = JSON.parse(response)
        response['user_reviews'].each do |review|
          new_review = Review.new
          new_review.review_rating = review['review']['rating']
          new_review.review_text = review['review']['review_text']
          new_review.rating_color = review['review']['rating_color']
          new_review.rating_text = review['review']['rating_text']
          new_review.review_time_stamp = Time.at(review['review']['timestamp'].to_i).to_time.to_i
          new_review.likes = review['review']['likes']
          new_review.author_name = review['review']['user']['name']
          new_review.author_foodie_level = review['review']['user']['foodie_level']
          new_review.user_image = review['review']['user']['profile_image']
          new_review.comments_count = review['review']['comments_count']
          new_review.restaurant_id = self.zomato_restaurant_id
          new_review.save
        end
      end
    end
  end

  # Get Ranking_score
  def get_ranking
    scorer = self.zomato_votes_count.to_i > 30 ? self.zomato_votes_count * 0.1 : 0
    self.ranking_score = scorer + self.zomato_user_rating * 10
    true
  end

  def comprehensive_rating_history
    list = eval(self.nearby_restaurants)
    list.push self.zomato_restaurant_id
    get_rating_history list
  end

  # List - Single or multiple Zomato_restaurant_ids
  def get_rating_history(list)
    neighbor_reviews = Review.where(restaurant_id: list).order(:review_time_stamp).all
    self_reviews = Review.where(restaurant_id: self.zomato_restaurant_id).order(:review_time_stamp).all
    dayspan = DateTime.strptime(neighbor_reviews.last.review_time_stamp.to_s,'%s').mjd - DateTime.strptime(neighbor_reviews.first.review_time_stamp.to_s,'%s').mjd
    no_of_points = dayspan > 300 ? (dayspan/150).round : 0
    no_of_points = neighbor_reviews.count if no_of_points > neighbor_reviews.count
    no_of_points = 8 if no_of_points > 8
    if no_of_points != 0
      interval = ((neighbor_reviews.last.review_time_stamp - neighbor_reviews.first.review_time_stamp)/no_of_points).round
      i = 0
      history = {}
      self_history = {}
      comprehensive_history = []
      time_points = 0
      while i < no_of_points
        time_points = neighbor_reviews.first.review_time_stamp + interval*i
        local_reviews = neighbor_reviews.where("review_time_stamp >= ? AND review_time_stamp <= ?", time_points - interval/2, time_points + interval/2).order("ABS(review_time_stamp - #{time_points})").first(neighbor_reviews.count/no_of_points)
        self_local_reviews = self_reviews.where("review_time_stamp >= ? AND review_time_stamp <= ?", time_points - interval, time_points + interval).order("ABS(review_time_stamp - #{time_points})").first(self_reviews.count/no_of_points)
        unless local_reviews == 0
          sum = 0
          local_reviews.each do |item|
            sum += item.review_rating != 0 ? item.review_rating : (item.rating_text == 'Positive' ? 4 : 2)
          end
        end
        history[Time.at(time_points).to_date] = sum/local_reviews.count
        i += 1
        if self_local_reviews.count == 0
          self_history[Time.at(time_points).to_date] = ((sum/local_reviews.count) + self.zomato_user_rating)/2
        end
      end
      comprehensive_history.push history
      comprehensive_history.push self_history
      comprehensive_history
    else
      nil
    end
  end

  def get_food_quality
    res_ids = eval(Scenario.find(self.id).nearby_restaurants)
    nearby_restaurants = Scenario.select('zomato_user_rating').where(zomato_restaurant_id: res_ids).all
    ratings = {
        Poor: 0,
        Average: 0,
        Good: 0,
        Awesome: 0,
    }
    nearby_restaurants.each do |rest|
      case rest.zomato_user_rating
        when 0..2
          ratings[:Poor] += 1
        when 2.1..3
          ratings[:Average] += 1
        when 3.1..4
          ratings[:Good] += 1
        when 4.1..5
          ratings[:Awesome] += 1
      end
    end
    ratings
  end

  validates :business_name, presence: true, length: { maximum: 100 }
  validates :location_lat, presence: true
  validates :location_lng, presence: true
  validates :zomato_restaurant_id, presence: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
            format: { with: VALID_EMAIL_REGEX }
end
