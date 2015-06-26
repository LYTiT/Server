class Api::V1::FeedsController < ApiBaseController

	def create
		feed = Feed.new(:name => params[:name], :user => params[:user_id])
		feed.save

		render json: { id: feed.id }
	end

	def delete
		feed = Feed.find_by_id(params[:id])
		feed.destroy
	end

	def edit_name
		feed = Feed.find_by_id(params[:id])
		feed.update_columns(name: params[:name])
		render json: feed.as_json
	end

	def add_venue
		new_feed_venue = FeedVenue.new(:feed_id => params[:id], :venue_id => params[:venue_id])
		if new_feed_venue.save
			render json: { success: true }
		end
	end

	def remove_venue
		feed_venue = FeedVenue.new(:feed_id => params[:id], :venue_id => params[:venue_id])
		feed_venue.destroy
		render json: { success: true }
	end

	def get_comments
		feed = Feed.find_by_id(params[:id])
		@comments = feed.comments.page(params[:page]).per(25)
	end

end