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
    unathorized unless @venue.user == current_user
  end

  def venue_params
    params.fetch(:venue,{}).permit(:menu_link, venue_messages_attributes: [:message, :id, :_destroy, :position])
  end

end
