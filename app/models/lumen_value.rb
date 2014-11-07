class LumenValue < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment
	belongs_to :lytit_vote
end
