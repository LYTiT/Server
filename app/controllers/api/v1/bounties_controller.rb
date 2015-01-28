class Api::V1::BountiesController < ApiBaseController

  def create
    bounty_expiration = Time.now + params[:expiration].minutes
  	bounty = Bounty.new(:user_id => params[:user_id], :venue_id => params[:venue_id], :lumen_reward => params[:lumen_reward], :expiration => bounty_expiration, :media_type => params[:media_type], :comment => params[:comment])
  	@venue = Venue.find_by_id(params[:venue_id])
  	@user = User.find_by_id(params[:user_id])
  	@venue.outstanding_bounties = @venue.outstanding_bounties + 1
  	@user.lumens = @user.lumens - params[:lumen_reward]
    bounty.save
  	@venue.save
  	@user.save
  	render json: { success: true }
  end

  def destroy
  	@bounty = Bounty.find_by_id(params[:bounty_id])
  	@bounty.destroy
  	render json: { success: true }
  end

end
