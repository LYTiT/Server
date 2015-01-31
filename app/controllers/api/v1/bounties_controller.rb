class Api::V1::BountiesController < ApiBaseController

  def create
    bounty_expiration = Time.now + params[:expiration].to_i.minutes
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

  def get_claims
    @bounty = Bounty.find_by_id(params[:bounty_id])
    @comments = @bounty.venue_comments.page(params[:page]).per(12).order("created_at desc")
  end

  def viewed_claim
    @bounty = Bounty.find_by_id(params[:bounty_id])
    @bounty.viewed_claim
  end

  def accept_bounty_claim
    @venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
    @bounty_claim = @venue_comment.bounty_claim[0]
    @bounty_claim.accepted
    render json: { success: true }
  end

  def reject_bounty_claim
    @venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
    @bounty_claim = @venue_comment.bounty_claim[0]
    @bounty_claim.rejected
    render json: { success: true }
  end

  def get_bounty_claim_notification_details
    @bounty_claim = BountyClaim.find_by_id(params[:bounty_claim_id])
    @bounty = @bounty_claim.bounty
    @venue = @bounty_claim.bounty.venue
  end

  def get_bounty_claim_rejection_notificaion_details
  
  end

  def get_bounty_claim_accept_notification_details

  end

  def get_pricing_constants
    render 'bounty_pricing_constants.json.jbuilder'
  end

end
