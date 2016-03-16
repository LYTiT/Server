class Event < ActiveRecord::Base
	belongs_to :venue
	has_many :event_organizers, :dependent => :destroy
	has_many :event_announcements, :dependent => :destroy

	def full_creation(name, description, start_date, end_date, venue_id, low_image_url, medium_image_url, regular_image_url)
		
	end

	def Event.get_events(location, lat, long, radius, query, order)
		client = EventfulApi::Client.new(:oauth_token => '8fa0de8d90dd5406c64d', :oauth_secret => '354fce0db74408ca8de7')
		page_size = 100

		if location != nil
			if query != nil
				response_hash = client.get('/events/search', {:keywords => query, :location => location, :date => 'Today', :page_size => page_size, :sort_order => order, :include => "popularity"})
			else
				response_hash = client.get('/events/search', {:location => location, :date => 'Today', :page_size => page_size, :sort_order => order})
			end
		else
			if query != nil
				response_hash = client.get('/events/search', {:keywords => query, :location => "#{lat},#{long}", :within => radius, :units => "km", :date => 'Today', :page_size => page_size, :sort_order => order})
			else
				response_hash = client.get('/events/search', {:location => "#{lat},#{long}", :within => radius, :units => "km", :date => 'Today', :page_size => page_size, :sort_order => order})
			end
		end
		response_hash["events"]["event"].each{|x| p"#{x["title"]} (#{x["venue_name"]})"} 
		p"------------------------------------------------------------------------------------------"
		response_hash
	end
end