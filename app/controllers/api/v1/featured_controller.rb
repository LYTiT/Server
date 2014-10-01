class Api::V1::FeaturedController < ApplicationController
respond_to :json	

  def today
  	selected_date = params[:featured_id]
  	now = Date.parse(selected_date)
  	v = VenueComment.where("DATE(created_at) = DATE(?) AND media_type = ?", now, 'image')
  	s = v.sort_by {|i| i.total_views}
  	@venue_comments = s.reverse.first(5)
  end

  def allTime
  	selected_date = params[:featured_id]
  	now = Date.parse(selected_date)
  	v = VenueComment.where("DATE(created_at) = DATE(?) AND media_type = ?", now, 'video')
  	s = v.sort_by {|i| i.total_views}
  	@venue_comments = s.reverse.first(5)
  end

  def profile_comments
    @user = User.find_by_id(params[:featured_id])
    if not @user
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["User not found"] } }, :status => :not_found
    else
      v = @user.venue_comments.where("username_private = 'false'")
      @comments = v.page(params[:page]).per(5).order("updated_at desc")
    end

  end

end