class Api::V1::FeaturedController < ApplicationController
respond_to :json  

  def today
    selected_date = params[:featured_id]
    now = Date.parse(selected_date)
    start_t = (now + 4.hour)
    end_t = (now + 28.hour)
    v = VenueComment.where("media_type = 'image' OR media_type = 'video' AND created_at <= ? AND created_at >= ?", end_t, start_t)
    s = v.sort_by {|i| i.views}
    @venue_comments = s.reverse.first(10)
  end

=begin
    def allTime
    selected_date = params[:featured_id]
    now = Date.parse(selected_date)
    now_1 = (now + 4.hour)
    now_2 = (now + 28.hour)
    v = VenueComment.where("media_type = 'video' AND created_at <= ? AND created_at >= ?", now_2, now_1)
    s = v.sort_by {|i| i.total_views}
    @venue_comments = s.reverse.first(5)
  end
=end

  def profile_comments
    @user = User.find_by_id(params[:featured_id])
    if not @user
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["User not found"] } }, :status => :not_found
    else
      v = @user.venue_comments.where("username_private = 'false'")
      @comments = v.page(params[:page]).per(5).order("updated_at desc")
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
