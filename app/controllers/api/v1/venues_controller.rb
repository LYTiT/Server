class Api::V1::VenuesController < ApiBaseController
  def index
    @venues = Venue.search(params)

    render json: @venues
  end

  def show
    @venue = Venue.find(params[:id])

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

  private

  def venue
    @venue ||= Venue.find(params[:venue_id])
  end

  def venue_comment_params
    params.permit(:comment, :media_type, :media_url)
  end
end
