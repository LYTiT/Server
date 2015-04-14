class Api::V1::LumenGameWinners < ApiBaseController
	def update_winner_paypal_info
		@winner = LumenGameWinner.find_by_id(params[:lumen_game_winner_id])
		@winner.paypal_info = params[:lumen_game_winner_id]
		@winner.save
		founder_1 = User.find_by_email("leonid@lytit.com")
      	founder_2 = User.find_by_name("tim@lytit.com")
      	Mailer.delay.notify_admins_of_winner_paypal_info_provided(founder_1, @winner.user)
      	Mailer.delay.notify_admins_of_winner_paypal_info_provided(founder_2, @winner.user)
		render json: { success: true }
	end
end

