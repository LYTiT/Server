class Api::V1::VenuesController < ApiBaseController

  skip_before_filter :set_user, only: [:search, :index]

  def index
    @venues = Venue.search(params)
  end

  def show
    @venue = Venue.find(params[:id])
    @venue.populate_google_address
    render json: @venue
  end

  def add_comment
    @comment = VenueComment.new(venue_comment_params)
    @comment.venue = venue
    @comment.user = @user

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
    v = LytitVote.new(:value => vote_value, :venue_id => params[:venue_id], :user_id => @user.id)

    venue = Venue.find(params[:venue_id])
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
