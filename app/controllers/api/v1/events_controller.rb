class Api::V1::EventsController < ApiBaseController

  skip_before_filter :set_user, only: [:index, :show]

  def index
    @events = Event.all
    render json: @event.to_json(:include => [:groups, :venue])
  end

  def create
    @event = Event.new(event_params)
    @event.user_id = @user.id
    if @event.save
      render json: @event.to_json(:include => [:groups])
    else
      render json: { error: { code: ERROR_UNPROCESSABLE, messages: @event.errors.full_messages } }, status: :unprocessable_entity
    end
  end

  def show
    @event = Event.find(params[:id])
    event = @event.as_json(:include => [:venue])
    event[:groups] = @event.user_groups(@user)
    render json: event
  end

  def report
    event = Event.find(params[:event_id])
    fe = FlaggedEvent.new
    fe.user_id = @user.id
    fe.message = params[:message]
    fe.event_id = event.id
    fe.save
    render json: fe
  end

  private

  def event_params
    params.require(:event).permit(:name, :description, :is_public, :start_date, :end_date, :location_name, :latitude, :longitude, :venue_id, :address, :city, :state, :postal_code, :formatted_address, :events_groups_attributes => [:group_id])
  end

end
