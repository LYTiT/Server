class Api::V1::VenuesController < ApplicationController
  def index
    @venues = Venue.search(params)

    render json: @venues
  end

  def show
    @venue = Venue.find(params[:id])

    render json: @venue
  end
end
