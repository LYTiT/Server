class BountySubscriber < ActiveRecord::Base
	belongs_to :user
	belongs_to :bounty
end