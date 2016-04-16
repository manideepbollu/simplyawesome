class Sentiment < ActiveRecord::Base
  belongs_to :entity
  belongs_to :review
end
