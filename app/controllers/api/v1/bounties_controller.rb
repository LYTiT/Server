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
		render json: { success: true }
	end

	def get_claims
		@bounty = Bounty.find_by_id(params[:bounty_id])
		@comments = @bounty.valid_bounty_claim_venue_comments.page(params[:page]).per(12).order("created_at desc")
	end

	def viewed_claim
		@bounty = Bounty.find_by_id(params[:bounty_id])
		@bounty.viewed_claim
		render json: { success: true }
	end

	def accept_bounty_claim
		@venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
		@bounty_claim = @venue_comment.bounty_claim
		@bounty_claim.acceptance
		render json: { success: true }
	end

	def reject_bounty_claim
		@venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
		@bounty_claim = @venue_comment.bounty_claim
		reason = params[:reason]
		@bounty_claim.rejection(reason)
		@bounty_claim.save
		render json: { success: true }
	end

	def get_bounty_claim_notification_details
		@bounty_claim = BountyClaim.find_by_id(params[:bounty_claim_id])
		@bounty = @bounty_claim.bounty
		@venue = @bounty_claim.bounty.venue
	end

	def get_bounty_claim_acceptance_notification_details
		@bounty_claim = BountyClaim.find_by_id(params[:bounty_claim_id])
		@bounty = @bounty_claim.bounty
		@venue = @bounty_claim.bounty.venue
	end

	def get_bounty_claim_rejection_notificaion_details
		@bounty_claim = BountyClaim.find_by_id(params[:bounty_claim_id])
		@bounty = @bounty_claim.bounty
		@venue = @bounty_claim.bounty.venue
	end

	def get_pricing_constants
		render 'bounty_pricing_constants.json.jbuilder'
	end

	def get_feed
		feed = Bounty.bounty_feed
		@bounty_feed = Kaminari.paginate_array(feed).page(params[:page]).per(10)
	end

end
