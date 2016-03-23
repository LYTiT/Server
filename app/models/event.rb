class Event < ActiveRecord::Base
	belongs_to :venue
	has_many :event_organizers, :dependent => :destroy
	has_many :event_announcements, :dependent => :destroy


	def Event.pull_city_events(city, day)
		city_events = Event.ping_eventbrite(city, nil, day)
		city_events.each{|event| Event.create_event_object(event)}
	end

	def Event.create_event_object(eventbrite_event)
		if (eventbrite_event != nil and eventbrite_event.venue.name != nil) && Event.find_by_id(eventbrite_event.id).present? == false
			clean_event_name = eventbrite_event.name.text.gsub("\n", "").first(140) rescue nil
			clean_event_description = eventbrite_event.description.text.gsub("\n", "") rescue nil
			venue = Venue.fetch(eventbrite_event.venue.name.to_s.titleize, eventbrite_event.venue.address.address_1, eventbrite_event.venue.address.city, nil, "United States", eventbrite_event.venue.address.postal_code, nil, eventbrite_event.venue.latitude, eventbrite_event.venue.longitude)
			new_event = Event.create!(:name => clean_event_name, :eventbrite_id => eventbrite_event.id, :description => clean_event_description, 
				:start_time => eventbrite_event.start.utc.to_datetime, :end_time => eventbrite_event.end.utc.to_datetime, :source_url => eventbrite_event.url, 
				:source => "Eventbrite", :venue_id => venue.id, :category => eventbrite_event.category.try(:name), :cover_image_url => eventbrite_event.logo.try(:url))
			venue.update_columns(event_id: new_event.id)
		else
			p "Event not created."
		end
	end

	def Event.ping_eventbrite(city, query, day)
=begin		
		eventbrite_categories = {"Music"=>{"id"=>103, "short_name"=>"Music"}, "Business & Professional"=>{"id"=>101, "short_name"=>"Business"}, "Food & Drink"=>{"id"=>110, "short_name"=>"Food & Drink"}, 
			"Community & Culture"=>{"id"=>113, "short_name"=>"Community"}, "Performing & Visual Arts"=>{"id"=>105, "short_name"=>"Arts"}, "Film, Media & Entertainment"=>{"id"=>104, "short_name"=>"Film & Media"}, 
			"Sports & Fitness"=>{"id"=>108, "short_name"=>"Sports & Fitness"}, "Health & Wellness"=>{"id"=>107, "short_name"=>"Health"}, "Science & Technology"=>{"id"=>102, "short_name"=>"Science & Tech"}, 
			"Travel & Outdoor"=>{"id"=>109, "short_name"=>"Travel & Outdoor"}, "Charity & Causes"=>{"id"=>111, "short_name"=>"Charity & Causes"}, "Religion & Spirituality"=>{"id"=>114, "short_name"=>"Spirituality"}, 
			"Family & Education"=>{"id"=>115, "short_name"=>"Family & Education"}, "Seasonal & Holiday"=>{"id"=>116, "short_name"=>"Holiday"}, "Government & Politics"=>{"id"=>112, "short_name"=>"Government"}, 
			"Fashion & Beauty"=>{"id"=>106, "short_name"=>"Fashion"}, "Home & Lifestyle"=>{"id"=>117, "short_name"=>"Home & Lifestyle"}, "Auto, Boat & Air"=>{"id"=>118, "short_name"=>"Auto, Boat & Air"}, 
			"Hobbies & Special Interest"=>{"id"=>119, "short_name"=>"Hobbies"}, "Other"=>{"id"=>199, "short_name"=>"Other"}} 
=end
		Eventbrite.token = 'JYGBS235A2RDI3YLHQLJ'
		day = day || "today"
		if query != nil
			events = Eventbrite::Event.search({"q"=>query, "venue.city" => city, "start_date.keyword" => day, "expand" => "venue,category,subcategory"})
		else
			events = Eventbrite::Event.search({"venue.city" => city, "start_date.keyword" => day, "expand" => "venue,category,subcategory"})
		end
		all_events = events.events
		while events.next?
		  if query != nil
		  	events = Eventbrite::Event.search({"q"=>query, "venue.city" => city, "start_date.keyword" => day, "expand" => "venue,category,subcategory", "page" => events.next_page})
		  else
		  	events = Eventbrite::Event.search({"venue.city" => city, "start_date.keyword" => day, "expand" => "venue,category,subcategory", "page" => events.next_page})
		  end
		  
		  all_events.concat(events.events)
		end
		return all_events
	end

=begin
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
		response_hash
	end
=end		

end