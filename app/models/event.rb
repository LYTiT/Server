class Event < ActiveRecord::Base
	belongs_to :venue
	has_many :event_organizers, :dependent => :destroy
	has_many :event_announcements, :dependent => :destroy

	def full_creation(name, description, start_date, end_date, venue_id, low_image_url, medium_image_url, regular_image_url)
		
	end

	def Event.get_events(lat, long, query)
		client = EventfulApi::Client.new(:oauth_token => '8fa0de8d90dd5406c64d', :oauth_secret => '354fce0db74408ca8de7')
		response_hash = client.get('/events/search', {:location => 'New York', :date => 'Today', :page_size => "1000"})
		response_hash["events"]["event"].each{|x| p"#{x["title"]}"} 
	end
end