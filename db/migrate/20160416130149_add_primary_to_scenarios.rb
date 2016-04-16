class AddPrimaryToScenarios < ActiveRecord::Migration
  def change
    add_column :scenarios, :primary, :boolean
  end
end
