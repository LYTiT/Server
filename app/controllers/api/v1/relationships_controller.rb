class Api::V1::RelationshipsController < ApplicationController

  def create
  	@user = User.find_by_id(params[:relationship_id])         #(params[:relationship][:relationship_id])
    current_user = User.find_by_authentication_token(params[:auth_token])
    current_user.follow!(@user)
  end

  def destroy
  	@user = User.find(params[:relationship_id])
  	current_user = User.find_by_authentication_token(params[:auth_token])
    current_user.unfollow!(@user)
  end

  def v_create
    @venue = Venue.find_by_id(params[:relationship_id])         #(params[:relationship][:relationship_id])
    current_user = User.find_by_authentication_token(params[:auth_token])
    current_user.vfollow!(@venue)
    render json: { success: true }
  end

  def v_destroy
    @venue = Venue.find_by_id(params[:relationship_id])
    current_user = User.find_by_authentication_token(params[:auth_token])
    current_user.vunfollow!(@venue)
    render json: { success: true }
  end
  
end
