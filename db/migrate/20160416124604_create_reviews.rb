class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      t.float :review_rating
      t.text :review_text
      t.string :rating_color
      t.string :rating_text
      t.timestamp :review_time_stamp
      t.integer :likes
      t.string :author_name
      t.string :author_foodie_level
      t.text :user_image
      t.integer :comments_count
      t.string :restaurant_id

      t.timestamps null: false
    end
  end
end
