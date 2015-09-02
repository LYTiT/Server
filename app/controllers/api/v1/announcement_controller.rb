class Api::V1::AccesscodesController < ApiBaseController

	def get_announcement_details
		@announcement = Announcement.find_by_id(params[:announcement_id])
	end

end