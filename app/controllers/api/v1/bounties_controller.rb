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
		original_subscriber = BountySubscriber.new(:user_id => params[:user_id], :bounty_id => bounty.id)
		original_subscriber.save
		response_venue_comment_housing = VenueComment.new(:comment => "This is a Moment Request", :media_type => params[:media_type], :venue_id => params[:venue_id], :bounty_id => bounty.id) #if a response comes in it will be loaded into this venue commment object.
		response_venue_comment_housing.save
		render json: { id: bounty.id }
	end

	def get_claims
		@bounty = Bounty.find_by_id(params[:bounty_id])
		@comments = @bounty.venue_comments.where("user_id IS NOT NULL AND (is_response_accepted = TRUE OR is_response_accepted IS NULL)").includes(:venue, :user, :comment_views).page(params[:page]).per(12).order("created_at desc")
	end

	def get_response_index
		#NOTE: make sure the itemst per page in the VIEW matches the per(xx) determinate below in the get_claims_for_global_feed
		@response = VenueComment.find_by_id(params[:venue_comment_id])
		@bounty = @response.bounty
	end

	def get_claims_for_global_feed
		@bounty = Bounty.find_by_id(params[:bounty_id])
		@comments = @bounty.venue_comments.where("user_id IS NOT NULL").includes(:venue, :user, :comment_views).page(params[:page]).per(12).order("created_at desc")
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
		@bounty_claim = VenueComment.find_by_id(params[:bounty_id])
		@bounty = @bounty_claim.bounty
	end

	def get_bounty_claim_accept_notification_details
		@bounty_claim = VenueComment.find_by_id(params[:bounty_id])
		@bounty = @bounty_claim.bounty
	end

	def get_bounty_claim_rejection_notification_details
		@bounty_claim = VenueComment.find_by_id(params[:bounty_id])
		@bounty = @bounty_claim.bounty
	end

	def get_pricing_constants
		@user = User.find_by_authentication_token(params[:auth_token])
		render 'bounty_pricing_constants.json.jbuilder'
	end

	def subscribe_to_bounty
		@user = User.find_by_authentication_token(params[:auth_token])
		new_subscription = BountySubscriber.new(:user_id => @user.id , :bounty_id => params[:bounty_id])
		new_subscription.save
		render json: { success: true }
	end

	def unsubscribe_from_bounty
		@user = User.find_by_authentication_token(params[:auth_token])
		subscription = BountySubscriber.where("user_id = #{params[:user_id]} and bounty_id = #{params[:bounty_id]}").first
		subscription.delete
		render json: { success: true}
	end

	def remove_bounty
		@bounty = Bounty.find_by_id(params[:bounty_id])
		@bounty.venue.decrement!(:outstanding_bounties, 1)
		@user = User.find_by_authentication_token(params[:auth_token])
		user_lumens = @user.lumens 
		@user.update_columns(lumens: user_lumens+@bounty.lumen_reward)
		housing_venue_comment = VenueComment.where("bounty_id = ? and user_id IS NULL", params[:bounty_id]).first
		housing_venue_comment.delete
		@bounty.delete
		render json: { success: true }
	end

	def update_bounty_details
		@bounty = Bounty.find_by_id(params[:bounty_id])
		if params[:venue_id] != nil
			@bounty.venue_id = params[:venue_id]
		end
		if	params[:lumen_reward] != nil
			@bounty.lumen_reward = params[:lumen_reward] 
		end
		if	params[:media_type] != nil
			@bounty.media_type = params[:media_type]
		end
		if	params[:comment] != nil
			@bounty.detail = params[:comment]
		end
		@bounty.save
		render json: { success: true }
	end

end
