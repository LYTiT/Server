class VenueQuestionComment < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_question


	def self.new_comment(v_q_id, comment, v_id, u_id, comment_user_on_location)
		new_venue_question_message = VenueQuestionComment.create!(:venue_question_id => v_q_id, :user_id => u_id, :comment => comment, :from_location => comment_user_on_location)
		new_venue_question_message.venue_question.increment(:num_comments, 1)
		new_venue_question_message.new_question_message_notification
	end
	
	def new_question_message_notification
		question_participant_ids = "SELECT user_id FROM venue_question_comments WHERE venue_question_id = #{self.venue_question_id}"
		question_participants = User.where("id IN (#{question_participant_ids})")

		for question_participant in question_participants
			if question_participant.id != self.user_id
				self.send_new_question_message_notification(question_participant)
			end
		end

	end

	def send_new_question_message_notification(question_participant)
		payload = {
		    :object_id => self.id, 
		    :activity_id => venue_question_id,
		    :activity_type => "question_notification",
		    :activity_user_name => venue_question.user.try(:name),
		    :activity_user_id => venue_question.user_id,
		    :activity_user_phone => venue_question.user.try(:phone_number),
		    :type => 'chat_notification', 
		    :user_id => user.id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,
		    :chat_message => self.comment,
		    :user_on_location => self.from_location,
		    :question => venue_question.question,
		    :venue_id => venue_question.venue_id,
		    :venue_name => venue_question.venue.name,
		    :latitude => venue_question.venue.latitude,
		    :longitude => venue_question.venue.longitude,
		    :city => venue_question.venue.city,
		    :color_rating => venue_question.venue.color_rating,
		    :activity_created_at => venue_question.created_at.to_i
		}
		
		if self.from_location == true && venue_question.num_comments == 1
			preview = "Someone responded to your question at #{venue_question.venue.name}!"
		else
			preview = "#{user.name} at #{venue_question.venue.name}: #{comment}"
		end

		notification_type = "question_comment/#{self.id}"

		notification = self.store_new_chat_notification(payload, question_participant, notification_type)
		payload[:notification_id] = notification.id
		
		if question_participant.push_token && question_participant.active == true
		  count = Notification.where(user_id: question_participant.id, read: false, deleted: false).count
		  APNS.send_notification(question_participant.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count})
		end
	end

	def store_new_chat_notification(payload, question_participant, type)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :user_id => question_participant.id,
		  :read => false,
		  :message => type,
		  :deleted => false
		}
		Notification.create(notification)
	end



end