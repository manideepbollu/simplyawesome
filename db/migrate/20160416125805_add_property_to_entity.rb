class AddPropertyToEntity < ActiveRecord::Migration
  def change
    add_column :entities, :property, :text
  end
end
