class Api::V1::FeaturedController < ApplicationController
respond_to :json  

  #Note that +4 and +28 is to account for the difference between EST and UCT times. Daylight savings also has to be considered (+1 hour).
  def today
    selected_date = params[:featured_id]
    selection = Date.parse(selected_date)
    start_t = (selection + 5.hour)
    end_t = (selection + 29.hour)
    photos = VenueComment.where("media_type = 'image' AND created_at <= ? AND created_at >= ? AND venue_id != 14002", end_t, start_t)
    videos = VenueComment.where("media_type = 'video' AND created_at <= ? AND created_at >= ? AND venue_id != 14002", end_t, start_t)
    content = photos + videos
    spotlyts = content.sort_by {|entry| entry.views}
    @venue_comments = spotlyts.reverse.first(10)
  end

  def profile_comments
    @user = User.find_by_id(params[:featured_id])
    if not @user
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["User not found"] } }, :status => :not_found
    else
      v = @user.venue_comments.where("username_private = 'false'")
      @comments = v.page(params[:page]).per(5).order("created_at desc")
    end
  end

  def allUsers
    @users = User.all
  end

  def search
    #@users = User.where("name = ? OR LOWER(name) like ?", params[:q].to_s, '%' + params[:q].to_s.downcase + '%')
    @user = User.find_by_authentication_token(params[:auth_token])
    if User.where("name = ?", params[:q].to_s).any?
      @person = User.where("name = ?", params[:q].to_s)
    else
      @person = User.where("name = ? OR LOWER(name) like ?", params[:q].to_s, '%' + params[:q].to_s.downcase + '%')
    end  
  end

end
