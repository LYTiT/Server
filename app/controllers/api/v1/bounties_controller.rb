class Api::V1::BountiesController < ApiBaseController

	def create
		bounty_expiration = Time.now + params[:expiration].to_i.minutes
		bounty = Bounty.new(:user_id => params[:user_id], :venue_id => params[:venue_id], :lumen_reward => params[:lumen_reward].to_f, :expiration => bounty_expiration, :media_type => params[:media_type], :detail => params[:comment])
		@venue = Venue.find_by_id(params[:venue_id])
		@user = User.find_by_id(params[:user_id])
		@venue.outstanding_bounties = @venue.outstanding_bounties + 1
		@venue.latest_placed_bounty_time = Time.now
		@user.lumens = @user.lumens - params[:lumen_reward]
		bounty.save
		@venue.save
		@user.save
		response_venue_comment_housing = VenueComment.new(:comment => "This is a Moment Request", :media_type => "text", :venue_id => params[:venue_id], :bounty_id => bounty.id) #if a response comes in it will be loaded into this venue commment object.
		response_venue_comment_housing.save
		render json: { success: true }
	end

	def get_claims
		@bounty = Bounty.find_by_id(params[:bounty_id])
		@comments = @bounty.venue_comments.where("user_id IS NOT NULL AND is_response_accepted != false").includes(:venue, :user).page(params[:page]).per(12).order("created_at desc")
	end

	def viewed_claim
		@bounty = Bounty.find_by_id(params[:bounty_id])
		@bounty.viewed_claim
		render json: { success: true }
	end

	def accept_bounty_claim
		@venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
		@venue_comment.claim_acceptance
		render json: { success: true }
	end

	def reject_bounty_claim
		@venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
		@venue_comment.claim_rejection(params[:reason])
		render json: { success: true }
	end

	def get_bounty_claim_notification_details
		@bounty_claim = VenueComment.find_by_id(params[:bounty_claim_id])
		@bounty = @bounty_claim.bounty
		@venue = @bounty_claim.bounty.venue
	end

	def get_bounty_claim_acceptance_notification_details
		@bounty_claim = VenueComment.find_by_id(params[:bounty_claim_id])
		@bounty = @bounty_claim.bounty
		@venue = @bounty_claim.bounty.venue
	end

	def get_bounty_claim_rejection_notificaion_details
		@bounty_claim = VenueComment.find_by_id(params[:bounty_claim_id])
		@bounty = @bounty_claim.bounty
		@venue = @bounty_claim.bounty.venue
	end

	def get_pricing_constants
		render 'bounty_pricing_constants.json.jbuilder'
	end


end
