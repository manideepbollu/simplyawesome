class CreateScenarios < ActiveRecord::Migration
  def change
    create_table :scenarios do |t|
      t.string :business_name
      t.string :email
      t.string :location_lat
      t.string :location_lng
      t.string :fips_state
      t.string :fips_county
      t.string :fips_tract
      t.string :fips_block_type
      t.string :zomato_postal_code
      t.integer :zomato_category_id
      t.integer :zomato_restaurant_id
      t.text :zomato_address
      t.string :zomato_cuisines
      t.integer :zomato_establishment_id
      t.integer :zomato_collection_id
      t.boolean :zomato_has_online_delivery
      t.integer :zomato_reviews_count
      t.float :zomato_user_rating
      t.string :zomato_rating_text
      t.string :zomato_rating_color
      t.integer :zomato_votes_count
      t.integer :zomato_price_range
      t.string :zomato_average_cost_for_two
      t.text :zomato_thumb
      t.text :zomato_reviews
      t.float :zomato_geo_popularity
      t.float :zomato_geo_nightlife
      t.integer :zomato_loc_entity_id
      t.string :zomato_loc_entity_type
      t.integer :zomato_loc_city_id
      t.string :zomato_loc_city
      t.string :geo_locality
      t.text :closer_zips
      t.text :closer_zips_coords
      t.text :nearest_zip
      t.text :nearest_zip_coords

      t.timestamps null: false
    end
  end
end
