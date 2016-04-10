class FeedJoinRequest < ActiveRecord::Base
	belongs_to :feed
	belongs_to :user

	after_create :new_request_notification

	def accepted(response)

	end

	def new_request_notification
	end

	def accepted_request_notification
	end

	def rejected_request_notification
	end

end