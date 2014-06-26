class Api::V1::VenuesController < ApiBaseController

  skip_before_filter :set_user, only: [:search, :index]

  def index
    @venues = Venue.search(params)
  end

  def show
    @venue = Venue.find(params[:id])
    @venue.populate_google_address
    render json: @venue.as_json(include: :venue_messages)
  end

  def add_comment
    @comment = VenueComment.new(venue_comment_params)
    @comment.venue = venue
    @comment.user = @user
    @comment.username_private = @user.username_private

    if not @comment.save
      render json: { error: { code: ERROR_UNPROCESSABLE, messages: @comment.errors.full_messages } }, status: :unprocessable_entity
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
    end
  end

  def mark_comment_as_viewed
    @comment = VenueComment.find_by_id_and_venue_id(params[:post_id], params[:venue_id])
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
    venues = Venue.fetch_venues('search', params[:q], params[:latitude], params[:longitude], params[:radius])
    render json: venues
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
    v = LytitVote.new(:value => vote_value, :venue_id => params[:venue_id], :user_id => @user.id, :venue_rating => rating ? rating : 0, :prime => venue.get_k)
    venue.account_new_vote(vote_value)

    if v.save
      render json: {"registered_vote" => vote_value, "venue_id" => params[:venue_id]}, status: :ok
    else
      render json: { error: { code: ERROR_UNPROCESSABLE, messages: v.errors.full_messages } }, status: :unprocessable_entity
    end
  end

  private

  def venue
    @venue ||= Venue.find(params[:venue_id])
  end

  def venue_comment_params
    params.permit(:comment, :media_type, :media_url)
  end
end
