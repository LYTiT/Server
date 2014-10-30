class Api::V1::VenuesController < ApiBaseController

  skip_before_filter :set_user, only: [:search, :index]

  def index
    @venues = Venue.fetch_venues('rankby', '', params[:lat], params[:lng], nil, nil, nil, params[:group_id])
  end

  def show
    @venue = Venue.find(params[:id])
    @venue.populate_google_address
    venue = @venue.as_json(include: :venue_messages)
    venue[:menu] = @venue.menu_sections.as_json(
      only: [:id, :name], 
      include: {
        :menu_section_items => {
          only: [:id, :name, :price, :description]
        }
      }
    )
    render json: venue
  end

  def add_comment
    @comment = VenueComment.new(venue_comment_params)
    @comment.venue = venue
    @comment.user = @user
    @comment.username_private = @user.username_private

    if not @comment.save
      render json: { error: { code: ERROR_UNPROCESSABLE, messages: @comment.errors.full_messages } }, status: :unprocessable_entity
    else 
      if @comment.media_type == 'text' and @comment.consider? == 1
        @user.update_lumens_after_text(@comment.id)
      end
    end

  end

  def delete_comment
    VenueComment.where(user_id: @user.id, id: params[:id]).destroy_all
    render json: { success: true }
  end

  def report_comment
    venue_comment = VenueComment.find(params[:comment_id])
    fc = FlaggedComment.new
    fc.user_id = @user.id
    fc.message = params[:message]
    fc.venue_comment_id = venue_comment.id
    fc.save
    render json: fc
  end

  def get_comments
    @venue = Venue.find_by_id(params[:venue_id])
    if not @venue
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue not found"] } }, :status => :not_found
    else
      @comments = @venue.visible_venue_comments.page(params[:page]).per(5).order("created_at desc")
    end
  end

  def mark_comment_as_viewed
    @comment = VenueComment.find_by_id_and_venue_id(params[:post_id], params[:venue_id])

    #consider is used for Lumen calculation. Initially it is set to 2 for comments with no views and then is
    #updated to the true value (1 or 0) for a particular comment after a view (comments with no views aren't considered
    #for Lumen calcuation by default)
    if @comment.consider > 1 
      @comment.consider?
      @comment.save
    end

    if (@comment.is_viewed?(@user) == false) #and (@comment.user_id != @user.id)
      poster_id = @comment.user_id
      poster = User.find_by(id: poster_id)
      poster.update_total_views
      @comment.update_views
      @comment.save
      if poster_id != @user.id
        @comment.calculate_adj_view
        @comment.save  
        poster.update_lumens_after_view(@comment)
      end
    end

    if @comment.present?
        comment_view = CommentView.new
        comment_view.user = @user
        comment_view.venue_comment = @comment
        comment_view.save
    else
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue / Post not found"] } }, :status => :not_found
      return
    end
  end


  def get_groups
    @venue = Venue.find_by_id(params[:venue_id])
    if @venue
      render json: @venue.groups
    else
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue not found"] } }, :status => :not_found
    end
  end

  def search
    @user = User.find_by_authentication_token(params[:auth_token])
    if params[:group_id].present? and not params[:q].present?
      @group = Group.find_by_id(params[:group_id])
      if @group
        render json: @group.venues_with_user_who_added
      else
        render json: { error: { code: ERROR_NOT_FOUND, messages: ["Group with id #{params[:group_id]} not found"] } }, status: :not_found
      end
    else
      @venues = Venue.fetch_venues('search', params[:q], params[:latitude], params[:longitude], params[:radius], params[:timewalk_start_time], params[:timewalk_end_time], params[:group_id], @user)
      if params[:timewalk_start_time].present? and params[:timewalk_end_time].present?
        render 'timewalk.json.jbuilder'
      else
        render 'search.json.jbuilder'
      end
    end
  end

  def rate_venue
    venue = Venue.find(params[:venue_id])
    @venue_rating = VenueRating.new(params.permit(:rating))
    @venue_rating.venue = venue
    @venue_rating.user = @user

    if @venue_rating.save
      render json: venue
    else
      render json: { error: { code: ERROR_UNPROCESSABLE, messages: @venue_rating.errors.full_messages } }, status: :unprocessable_entity
    end
  end

  def vote
    vote_value = params[:rating] > LytitBar.instance.position ? 1 : -1

    venue = Venue.find(params[:venue_id])
    rating = venue.rating
    v = LytitVote.new(:value => vote_value, :venue_id => params[:venue_id], :user_id => @user.id, :venue_rating => rating ? rating : 0, 
                      :prime => venue.get_k, :raw_value => params[:rating])
    

    if v.save
      venue.delay.account_new_vote(vote_value, v.id)
      @user.update_lumens_after_vote(v.id)
      render json: {"registered_vote" => vote_value, "venue_id" => params[:venue_id]}, status: :ok
    else
      render json: { error: { code: ERROR_UNPROCESSABLE, messages: v.errors.full_messages } }, status: :unprocessable_entity
    end
  end

  def followers
    @venue = Venue.find(params[:venue_id])
    @followers = @venue.followers
  end


  private

  def venue
    @venue ||= Venue.find(params[:venue_id])
  end

  def venue_comment_params
    params.permit(:comment, :media_type, :media_url)
  end
end
