class VenuesController < ApplicationController

  layout 'venue_manager'

  before_filter :authorize
  before_filter :authorized_manager?, only: [:show, :update]

  def reported_comments
    @flagged_comments = FlaggedComment.order('id DESC')
  end

  def show
    if @venue.to_param != params[:id] and params[:id].to_i == @venue.id
      redirect_to venue_path(@venue)
    end
  end

  def update
    if @venue.update_attributes(venue_params)
    else
    end
    redirect_to venue_path(@venue)
  end

  private

  def authorized_manager?
    @venue = Venue.find(params[:id])
    unless @venue.user == current_user
      #TODO: Something better could be done! This will currently display a 404 page.
      raise ActionController::RoutingError.new("Not authorized to access this page")
    end
  end

  def venue_params
    params.fetch(:venue,{}).permit(venue_messages_attributes: [:message, :id, :_destroy, :position])
  end

end
