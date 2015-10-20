class SupportIssue < ActiveRecord::Base
	belongs_to :user
	has_many :support_messages, :dependent => :destroy

	def unread_messages_present?
		self.latest_message_time >= latest_open_time
	end
end