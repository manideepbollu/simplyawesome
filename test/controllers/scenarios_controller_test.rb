require 'test_helper'

class ScenariosControllerTest < ActionController::TestCase
  setup do
    @scenario = scenarios(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:scenarios)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create scenario" do
    assert_difference('Scenario.count') do
      post :create, scenario: { business_name: @scenario.business_name, closer_zips: @scenario.closer_zips, closer_zips_coords: @scenario.closer_zips_coords, email: @scenario.email, fips_block_type: @scenario.fips_block_type, fips_county: @scenario.fips_county, fips_state: @scenario.fips_state, fips_tract: @scenario.fips_tract, geo_locality: @scenario.geo_locality, location_lat: @scenario.location_lat, location_lng: @scenario.location_lng, nearest_zip: @scenario.nearest_zip, nearest_zip_coords: @scenario.nearest_zip_coords, zomato_address: @scenario.zomato_address, zomato_average_cost_for_two: @scenario.zomato_average_cost_for_two, zomato_category_id: @scenario.zomato_category_id, zomato_collection_id: @scenario.zomato_collection_id, zomato_cuisines: @scenario.zomato_cuisines, zomato_establishment_id: @scenario.zomato_establishment_id, zomato_geo_nightlife: @scenario.zomato_geo_nightlife, zomato_geo_popularity: @scenario.zomato_geo_popularity, zomato_has_online_delivery: @scenario.zomato_has_online_delivery, zomato_loc_city: @scenario.zomato_loc_city, zomato_loc_city_id: @scenario.zomato_loc_city_id, zomato_loc_entity_id: @scenario.zomato_loc_entity_id, zomato_loc_entity_type: @scenario.zomato_loc_entity_type, zomato_postal_code: @scenario.zomato_postal_code, zomato_price_range: @scenario.zomato_price_range, zomato_rating_color: @scenario.zomato_rating_color, zomato_rating_text: @scenario.zomato_rating_text, zomato_restaurant_id: @scenario.zomato_restaurant_id, zomato_reviews: @scenario.zomato_reviews, zomato_reviews_count: @scenario.zomato_reviews_count, zomato_thumb: @scenario.zomato_thumb, zomato_user_rating: @scenario.zomato_user_rating, zomato_votes_count: @scenario.zomato_votes_count }
    end

    assert_redirected_to scenario_path(assigns(:scenario))
  end

  test "should show scenario" do
    get :show, id: @scenario
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @scenario
    assert_response :success
  end

  test "should update scenario" do
    patch :update, id: @scenario, scenario: { business_name: @scenario.business_name, closer_zips: @scenario.closer_zips, closer_zips_coords: @scenario.closer_zips_coords, email: @scenario.email, fips_block_type: @scenario.fips_block_type, fips_county: @scenario.fips_county, fips_state: @scenario.fips_state, fips_tract: @scenario.fips_tract, geo_locality: @scenario.geo_locality, location_lat: @scenario.location_lat, location_lng: @scenario.location_lng, nearest_zip: @scenario.nearest_zip, nearest_zip_coords: @scenario.nearest_zip_coords, zomato_address: @scenario.zomato_address, zomato_average_cost_for_two: @scenario.zomato_average_cost_for_two, zomato_category_id: @scenario.zomato_category_id, zomato_collection_id: @scenario.zomato_collection_id, zomato_cuisines: @scenario.zomato_cuisines, zomato_establishment_id: @scenario.zomato_establishment_id, zomato_geo_nightlife: @scenario.zomato_geo_nightlife, zomato_geo_popularity: @scenario.zomato_geo_popularity, zomato_has_online_delivery: @scenario.zomato_has_online_delivery, zomato_loc_city: @scenario.zomato_loc_city, zomato_loc_city_id: @scenario.zomato_loc_city_id, zomato_loc_entity_id: @scenario.zomato_loc_entity_id, zomato_loc_entity_type: @scenario.zomato_loc_entity_type, zomato_postal_code: @scenario.zomato_postal_code, zomato_price_range: @scenario.zomato_price_range, zomato_rating_color: @scenario.zomato_rating_color, zomato_rating_text: @scenario.zomato_rating_text, zomato_restaurant_id: @scenario.zomato_restaurant_id, zomato_reviews: @scenario.zomato_reviews, zomato_reviews_count: @scenario.zomato_reviews_count, zomato_thumb: @scenario.zomato_thumb, zomato_user_rating: @scenario.zomato_user_rating, zomato_votes_count: @scenario.zomato_votes_count }
    assert_redirected_to scenario_path(assigns(:scenario))
  end

  test "should destroy scenario" do
    assert_difference('Scenario.count', -1) do
      delete :destroy, id: @scenario
    end

    assert_redirected_to scenarios_path
  end
end
