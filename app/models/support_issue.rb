class SupportIssue < ActiveRecord::Base
	belongs_to :user
	has_many :support_messages, :dependent => :destroy

	def unread_messages_present?
		if self.latest_message_time != nil && self.latest_open_time != nil
			self.latest_message_time >= self.latest_open_time
		else
			false
		end
	end
end