class LytitVote < ActiveRecord::Base
  validates :value, presence: true
  validates_inclusion_of :value, in: [1, -1]

  belongs_to :venue
  belongs_to :user
end
