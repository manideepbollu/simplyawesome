class DeleteEmotionAndSentiment < ActiveRecord::Migration
  def change
    drop_table :sentiments
    add_column :entities, :sentiment, :string
    add_column :entities, :sentiment_type, :string
  end
end
