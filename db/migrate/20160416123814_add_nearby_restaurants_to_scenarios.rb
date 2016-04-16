class AddNearbyRestaurantsToScenarios < ActiveRecord::Migration
  def change
    add_column :scenarios, :nearby_restaurants, :text
  end
end
