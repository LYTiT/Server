class LumenValue < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment
	belongs_to :lytit_vote
	belongs_to :bounty

	after_create :new_lumens_notification
	after_create :calibrate_viewing_discount


	def new_lumens_notification
		if ( (user.lumens - user.lumen_notification) >= LumenConstants.notification_delta ) && user.version_compatible?("3.1.0") == true
			self.delay.send_new_lumens_notification
			user.lumen_notification = (user.lumens/LumenConstants.notification_delta).floor*LumenConstants.notification_delta
			user.save
			#user.update_lumen_percentile
		end
	end

	#for the Lumen games we check if the user receiving the Lumens has become a winner
	def is_a_winner?
		today = Time.now	
		if today.month != (today + 1.day).month
			if user.lumens >= 100.0 and user.email.last(3) == "edu"
				if Winner.where("user_id = ?", self.user_id).any? == false and Winner.where("created_at > ?", today-1.month).count < 50
					winner_code = self.generate_winning_code
					Winner.create!(user_id: user_id, winning_validation_code: winner_code)
				end
			end
		end
	end

	def self.generate_winning_code
		key_hash = { "N" => 0, "E" => 1, "W" => 7, "Y" => 6, "O" => 2, "R" => 4, "K" =>0}
		encrypt = [1, 7, 3]

		value_1 = rand(0..9)
		value_2 = rand(0..9)
		value_3 = rand(0..9)
		value_4 = "NEWYORK"[rand(0..6)]
		basis = value_1*value_2*value_3*key_hash[value_4] 
		if basis == 0
			value_5= encrypt.sample(1).first
		elsif basis <= 21
			value_5 = 21 - basis
		else
			value_5 = 21*(basis.to_f/21.0).ceil-basis
		end

		return value_1.to_s+value_2.to_s+value_3.to_s+value_4.to_s+value_5.to_s
	end


	def send_new_lumens_notification
		payload = {
		    :object_id => self.id, 
		    :type => 'new_lumens', 
		    :user_id => user.id
		}
		lumens_received = LumenConstants.notification_delta.to_i
		message = "+#{lumens_received} lumens received! You now have #{user.lumens.floor} lumens"
		notification = self.store_new_lumens_notification(payload, message)
		payload[:notification_id] = notification.id

		if user.push_token
		  count = Notification.where(user_id: user.id, read: false).count
		  APNS.delay.send_notification(user.push_token, { :priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
		end

		if user.gcm_token
		  gcm_payload = payload.dup
		  gcm_payload[:message] = message
		  options = {
		    :data => gcm_payload
		  }
		  request = HiGCM::Sender.new(ENV['GCM_API_KEY'])
		  request.send([user.gcm_token], options)
		end

	end

	def store_new_lumens_notification(payload, message)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => notification_payload,
		  :user_id => user.id,
		  :read => false,
		  :message => message,
		  :deleted => false
		}
		Notification.create(notification)
	end

	def notification_payload
	  {
	    :new_lumens => {
	      :addition => LumenConstants.notification_delta.to_i,
	      :lumens => user.lumens,
	    }
	    
	  }
	end

	#Calibrate user viewing discount based for Lumen calculation based on unique viewers percentage. We calibrate after every 5 Lumens
	def calibrate_viewing_discount
		if self.venue_comment_id != nil #not dealing with a Vote
			if ((user.lumens.floor % LumenConstants.view_discount_calibration_delta.to_i) == 0) && self.try(:venue_comment).media_type != 'text'
				unique_viewers = CommentView.joins(:venue_comment).where('venue_comments.user_id = ?', user.id).uniq.pluck(:user_id)
				total_viewers = CommentView.joins(:venue_comment).where('venue_comments.user_id = ?', user.id).pluck(:user_id)
				unique_viewers_percentage = unique_viewers/total_viewers

				user.adjusted_view_discount = LumenConstants.views_weight_adj*(unique_viewers_percentage)**(1/LumenConstants.views_weight_adj_damping)
				user.save
			end
		end
	end

end
