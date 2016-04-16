# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160416181453) do

  create_table "emotions", force: :cascade do |t|
    t.string   "emotion_type"
    t.string   "score"
    t.integer  "review_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "emotions", ["review_id"], name: "index_emotions_on_review_id"

  create_table "entities", force: :cascade do |t|
    t.string   "entity"
    t.string   "entity_type"
    t.integer  "review_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.text     "property"
    t.string   "sentiment"
    t.string   "sentiment_type"
  end

  add_index "entities", ["review_id"], name: "index_entities_on_review_id"

  create_table "reviews", force: :cascade do |t|
    t.float    "review_rating"
    t.text     "review_text"
    t.string   "rating_color"
    t.string   "rating_text"
    t.datetime "review_time_stamp"
    t.integer  "likes"
    t.string   "author_name"
    t.string   "author_foodie_level"
    t.text     "user_image"
    t.integer  "comments_count"
    t.string   "restaurant_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "scenarios", force: :cascade do |t|
    t.string   "business_name"
    t.string   "email"
    t.string   "location_lat"
    t.string   "location_lng"
    t.string   "fips_state"
    t.string   "fips_county"
    t.string   "fips_tract"
    t.string   "fips_block_type"
    t.string   "zomato_postal_code"
    t.integer  "zomato_category_id"
    t.integer  "zomato_restaurant_id"
    t.text     "zomato_address"
    t.string   "zomato_cuisines"
    t.integer  "zomato_establishment_id"
    t.integer  "zomato_collection_id"
    t.boolean  "zomato_has_online_delivery"
    t.integer  "zomato_reviews_count"
    t.float    "zomato_user_rating"
    t.string   "zomato_rating_text"
    t.string   "zomato_rating_color"
    t.integer  "zomato_votes_count"
    t.integer  "zomato_price_range"
    t.string   "zomato_average_cost_for_two"
    t.text     "zomato_thumb"
    t.text     "zomato_reviews"
    t.float    "zomato_geo_popularity"
    t.float    "zomato_geo_nightlife"
    t.integer  "zomato_loc_entity_id"
    t.string   "zomato_loc_entity_type"
    t.integer  "zomato_loc_city_id"
    t.string   "zomato_loc_city"
    t.string   "geo_locality"
    t.text     "closer_zips"
    t.text     "closer_zips_coords"
    t.text     "nearest_zip"
    t.text     "nearest_zip_coords"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.text     "nearby_restaurants"
    t.boolean  "primary"
  end

end
