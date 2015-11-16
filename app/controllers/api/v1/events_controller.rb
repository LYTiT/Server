class Api::V1::EventsController < ApiBaseController
	def show
		@event = Event.find_by_id(params[:id])
	end

	def get_announcements
		@event_announcements =  EventAnnouncement.where("event_id = ?", params[:event_id]).order("id DESC").page(params[:page]).per(10)
	end

	def create_event
	end

end