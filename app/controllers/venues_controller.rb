class VenuesController < ApplicationController

  layout 'venue_manager'

  def reported_comments
    @flagged_comments = FlaggedComment.order('id DESC')
  end

  def show
    @venue = Venue.find(params[:id])
  end

end
