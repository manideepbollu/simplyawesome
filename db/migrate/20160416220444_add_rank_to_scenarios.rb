class AddRankToScenarios < ActiveRecord::Migration
  def change
    add_column :scenarios, :ranking_score, :float
  end
end
