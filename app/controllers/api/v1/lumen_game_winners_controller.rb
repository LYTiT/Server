class Api::V1::LumenGameWinnersController < ApiBaseController

	def update_winner_paypal_info
		@winner = LumenGameWinner.find_by_id(params[:lumen_game_winner_id])
		@winner.paypal_info = params[:update_paypal_info]
		@winner.save
		founder_1 = User.find_by_email("leonid@lytit.com")
      	founder_2 = User.find_by_name("tim@lytit.com")
      	if founder_1 != nil
      		Mailer.delay.notify_admins_of_user_paypal_details(founder_1, @winner.user)
      	end
      	if founder_2 != nil
      		Mailer.delay.notify_admins_of_user_paypal_details(founder_2, @winner.user)
		end
		render json: { success: true }
	end
end

