class Api::V1::EventsController < ApiBaseController

  skip_before_filter :set_user, only: [:index]

  def index
    @events = Event.all
    render json: @events.to_json(:include => [:groups])
  end

  def create
    @event = Event.new(event_params)
    @event.user_id = @user.id
    if @event.save
      render json: @event.to_json(:include => [:groups])
    else
      render json: { errors: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def event_params
    params.require(:event).permit(:name, :description, :is_public, :start_date, :end_date, :location_name, :latitude, :longitude, :venue_id, :events_groups_attributes => [:group_id])
  end

end
