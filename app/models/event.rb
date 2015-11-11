class Event < ActiveRecord::Base
	belongs_to :venue
	has_many :event_organizers, :dependent => :destroy
	has_many :event_announcements, :dependent => :destroy

	def full_creation(name, description, start_date, end_date, venue_id, low_image_url, medium_image_url, regular_image_url)
		
	end
end