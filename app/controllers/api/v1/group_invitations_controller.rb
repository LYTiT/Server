class Api::V1::GroupInvitationsController < ApplicationController

  def destroy
  	@invite = GroupInvitation.find_by_id(params[:group_invitation_id])
    @invite.active = false
    @invite.save
    render json: { success: true }
  end

  def validate_invitation
    @invite = GroupInvitation.find_by_id(params[:group_invitation_id])
    @validation = @invite.active
    render json: { validated: @validation }
  end

  def get_group_invite_notification_details
    @invite = GroupInvitation.find_by_id(params[:group_invitation_id])
    @group = @invite.igroup
    @invited = @invite.invited
    @host = @invite.host
  end

  def get_prospects 
    @user = User.find_by_id(params[:user_id])
    @prospects = @user.followers_not_in_group(@user.followers.to_a, params[:group_id])
  end


end
