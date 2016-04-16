class CreateEmotions < ActiveRecord::Migration
  def change
    create_table :emotions do |t|
      t.string :emotion_type
      t.string :score
      t.references :review, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
