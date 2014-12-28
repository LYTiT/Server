class Api::V1::AtGroupRelationshipsController < ApplicationController
	def get_at_group_notification_details
	    @at_group = AtGroupRelationship.find_by_id(params[:at_group_relationship_id])
	    @venue_comment = @at_group.venue_comment
	   	@group = @at_group.group
  	end

end