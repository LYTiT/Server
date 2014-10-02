class Api::V1::FeaturedController < ApplicationController
respond_to :json	

  def today
  	selected_date = params[:featured_id]
  	now = Date.parse(selected_date)
    now_1 = (now + 4.hour)
    now_2 = (now + 28.hour)
  	v = VenueComment.where("media_type = ? AND DATE(created_at) BETWEEN DATE(?) AND DATE(?)", 'image', now_1, now_2)
  	s = v.sort_by {|i| i.total_views}
  	@venue_comments = s.reverse.first(5)
  end

  def allTime
  	selected_date = params[:featured_id]
  	now = Date.parse(selected_date)
    now_1 = (now + 4.hour)
    now_2 = (now + 28.hour)
  	v = VenueComment.where("media_type = ? AND DATE(created_at) BETWEEN DATE(?) AND DATE(?)", 'video', now_1, now_2)
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