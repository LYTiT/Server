class Api::V1::VenuesController < ApiBaseController
  
  skip_before_filter :set_user, only: [:search]
  
  def index
    @venues = Venue.search(params)

    render json: @venues
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

    if @comment.save
      render json: @comment
    else
      render json: @comment.errors, status: :unprocessable_entity
    end
  end

  def get_comments
    @venue = Venue.find_by_id(params[:venue_id])
    if @venue
      render json: @venue.venue_comments
    else
      render json: {:error => "not-found"}.to_json, :status => 404
    end
  end

  def get_groups
    @venue = Venue.find_by_id(params[:venue_id])
    if @venue
      render json: @venue.groups
    else
      render json: {:error => "not-found"}.to_json, :status => 404
    end
  end
  
  def search
    venues = Venue.fetch_venues(params[:q], params[:latitude], params[:longitude])
    render json: venues
  end
  
  private

  def venue
    @venue ||= Venue.find(params[:venue_id])
  end

  def venue_comment_params
    params.permit(:comment, :media_type, :media_url)
  end
end
