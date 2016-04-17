class ChangeColumnTypeInReview < ActiveRecord::Migration
  def change
    change_column :reviews, :review_time_stamp, :integer
  end
end
