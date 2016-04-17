class ScenariosController < ApplicationController
  layout "google-layout", only: [:new, :edit]
  before_action :set_scenario, only: [:show, :edit, :update, :destroy]

  # GET /scenarios
  # GET /scenarios.json
  def index
    @scenarios = Scenario.where(primary: true)
  end

  # GET /scenarios/1
  # GET /scenarios/1.json
  def show
    nearby_list = eval(@scenario.nearby_restaurants)
    nearby_list.push @scenario.zomato_restaurant_id
    @ranked_list = Scenario.where(zomato_restaurant_id: nearby_list).order(ranking_score: :desc)
    @favorites = []
    @distance = []
    @ranked_list.each do |item|
      # Get the fav menu item for each restaurant
      reviews = Review.select('id').where(restaurant_id: item.zomato_restaurant_id).all.as_json
      arr = []
      reviews.each do |review| arr.push review['id'] end
      reviews = arr
      entity = Entity.where(review_id: reviews).where(sentiment_type: 'positive').order(sentiment: :desc)
      @favorites[item.zomato_restaurant_id] = entity.count != 0 ? entity.first.entity : 'Not available'
      # Get distance of each restaurant from primary restaurant
      response = RestClient.get "https://maps.googleapis.com/maps/api/distancematrix/json?origins=#{item.location_lat},#{item.location_lng}&destinations=#{@scenario.location_lat},#{@scenario.location_lng}&key=#{Rails.application.config.google_key}"
      response = JSON.parse(response)
      if response['status'] == 'OK' and response['rows'][0]['elements'][0]['status'] == 'OK'
        @distance[item.zomato_restaurant_id] = (response['rows'][0]['elements'][0]['distance']['value']*0.000621371).to_i.to_s
      else
        @distance[item.zomato_restaurant_id] = 'NA'
      end
    end

    # Get Neighborhood History
    @history = @scenario.comprehensive_rating_history

    #Food Quality
    @food_quality = @scenario.get_food_quality

    #Pop Stats
    @pop_stats = @scenario.get_pop_stats
    @pop_entities = {}
    @pop_entities[:white] = (@pop_stats[:whites]*100)/@pop_stats[:total]
    @pop_entities[:black] = (@pop_stats[:blacks]*100)/@pop_stats[:total]
    @pop_entities[:hispanic] = (@pop_stats[:hispanics]*100)/@pop_stats[:total]
    @pop_entities[:natives] = (@pop_stats[:american_natives]*100)/@pop_stats[:total]
    @pop_entities[:indian] = (@pop_stats[:indians]*100)/@pop_stats[:total]
    @pop_entities[:chinese] = (@pop_stats[:chinese]*100)/@pop_stats[:total]

    # Good and bad analysis
    arr = @scenario.get_good_bad_analysis
    @other_good = arr[0]
    @other_bad = arr[1]
    @good = arr[2]
    @bad = arr[3]
  end

  # GET /scenarios/new
  def new
    @scenario = Scenario.new
  end

  # GET /scenarios/1/edit
  def edit
  end

  # POST /scenarios
  # POST /scenarios.json
  def create
    @scenario = Scenario.new(scenario_params)

    respond_to do |format|
      if @scenario.save
        format.html { redirect_to @scenario, notice: 'Scenario was successfully created.' }
        format.json { render :show, status: :created, location: @scenario }
      else
        format.html { render :new }
        format.json { render json: @scenario.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scenarios/1
  # PATCH/PUT /scenarios/1.json
  def update
    respond_to do |format|
      if @scenario.update(scenario_params)
        format.html { redirect_to @scenario, notice: 'Scenario was successfully updated.' }
        format.json { render :show, status: :ok, location: @scenario }
      else
        format.html { render :edit }
        format.json { render json: @scenario.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scenarios/1
  # DELETE /scenarios/1.json
  def destroy
    @scenario.destroy
    respond_to do |format|
      format.html { redirect_to scenarios_url, notice: 'Scenario was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # GET /scenarios/get-restaurant-ids.json
  def get_restaurants
    term = params[:term]
    restaurant_list = []
    if term.length > 4
      response = RestClient.get "https://developers.zomato.com/api/v2.1/search?q=#{term}&count=5&lat=#{cookies[:lat]}&lon=#{cookies[:lng]}&radius=15000&sort=rating&order=desc", accept: :json, 'user-key' => Rails.application.config.zomato_key
      if response.code == 200
        response = JSON.parse(response)
        Parallel.each(response['restaurants'], in_threads: 5) { |item|
          restaurant_list.push({
             :label => item['restaurant']['name'] + ' at ' + item['restaurant']['location']['address'],
             :value => item['restaurant']['name'],
             :res_id => item['restaurant']['id'],
             :lat => item['restaurant']['location']['latitude'],
             :lng => item['restaurant']['location']['longitude'],
             :address => item['restaurant']['location']['address'],
             :city_id => item['restaurant']['location']['city_id'],
             :city => item['restaurant']['location']['city'],
             :postal_code => item['restaurant']['location']['zipcode'],
             :cuisines => item['restaurant']['cuisines'],
             :user_rating => item['restaurant']['user_rating']['aggregate_rating'],
             :rating_text => item['restaurant']['user_rating']['rating_text'],
             :rating_color => item['restaurant']['user_rating']['rating_color'],
             :votes_count => item['restaurant']['user_rating']['votes'],
             :has_online_delivery => item['restaurant']['has_online_delivery'],
             :price_range => item['restaurant']['price_range'],
             :average_cost_for_two => item['restaurant']['average_cost_for_two'],
             :thumb => item['restaurant']['thumb'],
          })
        }
      end
    end
    respond_to do |format|
      format.json { render :json => restaurant_list }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scenario
      @scenario = Scenario.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scenario_params
      params.require(:scenario).permit(:business_name, :email, :location_lat, :location_lng, :fips_state, :fips_county, :fips_tract, :fips_block_type, :zomato_postal_code, :zomato_category_id, :zomato_restaurant_id, :zomato_address, :zomato_cuisines, :zomato_establishment_id, :zomato_collection_id, :zomato_has_online_delivery, :zomato_reviews_count, :zomato_user_rating, :zomato_rating_text, :zomato_rating_color, :zomato_votes_count, :zomato_price_range, :zomato_average_cost_for_two, :zomato_thumb, :zomato_reviews, :zomato_geo_popularity, :zomato_geo_nightlife, :zomato_loc_entity_id, :zomato_loc_entity_type, :zomato_loc_city_id, :zomato_loc_city, :geo_locality, :closer_zips, :closer_zips_coords, :nearest_zip, :nearest_zip_coords)
    end
end
