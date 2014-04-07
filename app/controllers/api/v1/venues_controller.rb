class Api::V1::VenuesController < ApiBaseController
  skip_before_filter :set_user

  def index
    @venues = Venue.search(params)

    render json: @venues
  end

  def show
    @venue = Venue.find(params[:id])

    render json: @venue
  end
end
