class Api::V1::GroupInvitationsController < ApplicationController

  def destroy
  	@invite = GroupInvitation.find_by_id(params[:group_invitation_id])
    @invite.destroy
    render json: { success: true }
  end

  def validate_invitation
    @invite = GroupInvitation.find_by_id(params[:group_invitation_id])
    @validation = @invite ? true : false
    render json: {validated @validation }
    #render json: { success: validation }
  end

  def get_group_invite_notification_details
    @invite = GroupInvitation.find_by_id(params[:group_invitation_id])
    @group = @invite.igroup
    @invited = @invite.invited
    @host = @invite.host
  end

end
