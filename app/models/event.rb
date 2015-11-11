class Event < ActiveRecord::Base
	belongs_to :venue
	has_many :event_organizers, :dependent => :destroy
	has_many :event_announcements, :dependent => :destroy
end