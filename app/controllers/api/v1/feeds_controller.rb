class Api::V1::FeedsController < ApiBaseController
	skip_before_filter :set_user, only: [:create]

	def create
		feed = Feed.new(:name => params[:name], :user_id => params[:user_id])
		feed.save

		render json: feed.as_json
	end

	def delete
		feed = Feed.find_by_id(params[:id])
		feed.destroy

		render json: { success: true }
	end

	def edit_name
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
				render json: { success: true }
			end
		else
			render json: { success: false }
		end
	end

	def remove_venue
		feed_venue = FeedVenue.new(:feed_id => params[:id], :venue_id => params[:venue_id])
		feed_venue.destroy
		render json: { success: true }
	end

end