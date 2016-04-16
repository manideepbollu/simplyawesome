class CreateSentiments < ActiveRecord::Migration
  def change
    create_table :sentiments do |t|
      t.string :sentiment_type
      t.string :score
      t.text :comment
      t.references :entity, index: true, foreign_key: true
      t.references :review, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
