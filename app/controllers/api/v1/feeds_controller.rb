class Api::V1::FeedsController < ApiBaseController
	skip_before_filter :set_user, only: [:create]

	def create
		feed = Feed.new(:name => params[:name], :user_id => params[:user_id], :latest_viewed_time => Time.now, :feed_color => params[:feed_color])
		feed.save

		render json: feed.as_json
	end

	def delete
		feed = Feed.find_by_id(params[:id])
		feed.destroy

		render json: { success: true }
	end

	def edit_feed
		feed = Feed.find_by_id(params[:id])
		feed.update_columns(name: params[:name])
		render json: feed.as_json
	end

	def get_venues
		@venues = Feed.find_by_id(params[:id]).venues
	end

	def add_venue
		if FeedVenue.where("feed_id = ? AND venue_id = ?", params[:id], params[:venue_id]).any? == false
			new_feed_venue = FeedVenue.new(:feed_id => params[:id], :venue_id => params[:venue_id])
			if new_feed_venue.save
				Feed.find_by_id(params[:id]).increment!(:num_venues, 1)
				render json: { success: true }
			end
		else
			render json: { success: false }
		end
	end

	def add_raw_venue
		venue = Venue.fetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude], params[:pin_drop])
		if FeedVenue.where("feed_id = ? AND venue_id = ?", params[:feed_id], venue.id).any? == false
			new_feed_venue = FeedVenue.new(:feed_id => params[:feed_id], :venue_id => venue.id)
			if new_feed_venue.save
				Feed.find_by_id(params[:feed_id]).increment!(:num_venues, 1)
				render json: { id: venue.id }
			end
		else
			render json: { success: false }
		end
	end

	def remove_venue
		feed_venue = FeedVenue.where("feed_id = ? AND venue_id = ?", params[:id], params[:venue_id]).first
		feed_venue.destroy
		Feed.find_by_id(params[:id]).decrement!(:num_venues, 1)
		render json: { success: true }
	end

	def register_open
		feed = Feed.find_by_id(params[:feed_id])			
		feed.update_columns(latest_viewed_time: Time.now)
		feed.update_columns(new_media_present: false)
		#feed.update_media	
		render json: { success: true }
	end

end