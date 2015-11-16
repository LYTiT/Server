class Api::V1::EventsController < ApiBaseController
	def show
		@event = Event.find_by_id(params[:id])
	end

	def get_announcements
		@event_announcements = Event.find_by_id(params[:event_id]).event_announcements.order("id DESC").page(params[:page]).per(10)
	end

	def create_event
	end

end