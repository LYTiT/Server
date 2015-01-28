class Api::V1::BountyClaimsController < ApiBaseController

	def create
		bc = BountyClaim.new(:user_id => params[:user_id], :bounty_id => params[:bounty_id])
		bounty_claim.save
	end

	def post_accept
		bc = BountyClaim.find_by_id(params[:id])
		bc.accepted
		render json: { success: true }
	end

	def post_reject
		bc = BountyClaim.find_by_id(params[:id])
		bc.rejected
		render json: { success: true }
	end


end