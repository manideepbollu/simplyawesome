class CreateEntities < ActiveRecord::Migration
  def change
    create_table :entities do |t|
      t.string :entity
      t.string :entity_type
      t.references :review, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
