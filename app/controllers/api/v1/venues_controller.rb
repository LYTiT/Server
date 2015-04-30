class Api::V1::VenuesController < ApiBaseController

	skip_before_filter :set_user, only: [:search, :index]

	def show
		@user = User.find_by_authentication_token(params[:auth_token])
		@venue = Venue.find(params[:id])
		venue = @venue.as_json(include: :venue_messages)
		venue[:menu] = @venue.menu_sections.as_json(
			only: [:id, :name], 
			include: {
				:menu_section_items => {
					only: [:id, :name, :price, :description]
				}
			}
		)

		if @venue.is_hot? == true
			venue[:is_hot] = true
			venue[:bonus_lumens] = 1
		else
			venue[:is_hot] = false
			venue[:bonus_lumens] = nil
		end
		venue[:compare_type] = @venue.type

		render json: venue
	end

	def get_menue
		@venue = Venue.find(params[:id])
	end

	def get_bounties
		@user = User.find_by_authentication_token(params[:auth_token])
		@venue = Venue.find_by_id(params[:venue_id])
		raw_bounties = Bounty.where("venue_id = ? AND validity = true", @venue.id).order('id DESC')
		@bounties = []
		if raw_bounties.count > 0
			for bounty in raw_bounties
				if bounty.check_validity == true && bounty.expiration > Time.now
					@bounties << bounty
				end
			end
		end
	end

	def add_comment
		parts_linked = false #becomes 'true' when Venue Comment is formed by two parts conjoining
		assign_lumens = false #in v3.0.0 posting by parts makes sure that lumens are not assigned for the creation of the text part of a media Venue Comment

		session = params[:session]
		incoming_part_type = venue.id == 14002 ? "media" : "text" #we use the venue_id '14002' as a key to signal a posting by parts operation

		completion = false #add_comment method is completed either once a Venue Comment or a Temp Posting Housing object is created
		

		if session != 0 #simple text comments have a session id = 0 and do not need to be seperated into parts
			posting_parts = @user.temp_posting_housings.order('id ASC')

			if posting_parts.count == 0 #if no parts are housed there is nothing to link
				vc_part = TempPostingHousing.new(:user_id => @user.id, :venue_id => venue.id, :media_type => params[:media_type], :media_url => params[:media_url], 
																			:session => session, :comment => params[:comment], :username_private => params[:username_private])
				vc_part.save
				completion = true
				render json: { success: true }
			else
				for part in posting_parts #iterate through posting parts to find matching part (equivalent session id) of incoming Venue Comment part
					
					if part.session != nil and part.session == session
						@comment = VenueComment.new(venue_comment_params)
						@comment.user = @user
						@comment.venue = venue
						@comment.username_private = params[:username_private]
						if incoming_part_type == "media" #pull venue, comment and visability data as the incoming part is the media
							@comment.venue = part.venue
							@comment.comment = part.comment
							@comment.username_private = part.username_private
						else #pull media data as the incoming part is the text
							@comment.media_type = part.media_type
							@comment.media_url = part.media_url
						end
						part.delete
						parts_linked = true
						break  
					else #if a part has been housed for over a reasonable period of time we can assume that it is no longer needed.
						if (((Time.now - part.created_at) / 1.minute) >= 30.0)
							part.delete
						end
					end

				end

				if parts_linked == false #appropraite part has not arrived yet so we store the current part in temp housing
					vc_part = TempPostingHousing.new(:user_id => @user.id, :venue_id => venue.id, :media_type => params[:media_type], :media_url => params[:media_url], 
																				:session => session, :comment => params[:comment], :username_private => params[:username_private])          
					vc_part.save
					completion = true
					render json: { success: true }
				end
			end

		else #dealing with a simple text comment
			assign_lumens = true
			@comment = VenueComment.new(venue_comment_params)
			@comment.venue = venue
			@comment.user = @user
			@comment.username_private = params[:username_private]
		end


		if completion == false #a Venue Comment has been created instead of a Temp Posting Housing object so now it needs to be saved

			if not @comment.save
				render json: { error: { code: ERROR_UNPROCESSABLE, messages: @comment.errors.full_messages } }, status: :unprocessable_entity
			else
				#based off of the position an adjusted hour time is assigned to the venue comment which is used in Spotlyt
				offset = @comment.created_at.in_time_zone(@comment.venue.time_zone).utc_offset
				offset_time = @comment.created_at + offset
				@comment.offset_created_at = offset_time
				@comment.save

				venue.update_columns(latest_posted_comment_time: Time.now)

				if (@comment.media_type == 'text' and @comment.consider? == 1) and assign_lumens == true
					if @comment.comment.split.count >= 5 # far from science but we assume that if a Venue Comment is text it should have at least 5 words to be considered 'useful'
						@user.delay.update_lumens_after_text(@comment.id)
					end
				end

				#If the Venue Comment is a Bounty response we update bounty_id field
				if params[:is_bounty_response] != nil
					@comment.is_response = true
					@comment.bounty_id = params[:is_bounty_response]
					b = Bounty.find_by_id(params[:is_bounty_response])
					b.response_received = true
					b.increment!(:num_responses, 1)
					@comment.save
					b.save
					@comment.delay.send_bounty_claim_notification
				end

				#if a hot venue and valid bonus post assign user bonus lumens
				if params[:bonus_lumens] != nil
					@user.delay.account_new_bonus_lumens(params[:bonus_lumens])
				end

				#LYTiT it UP!
				rating = venue.rating
				v = LytitVote.new(:value => 1, :venue_id => venue.id, :user_id => @user.id, :venue_rating => rating ? rating : 0, 
													:prime => 0.0, :raw_value => 1.0)

				if v.save
					venue.delay.account_new_vote(1, v.id)

					if LytSphere.where("venue_id = ?", venue.id).count == 0
						LytSphere.delay.create_new_sphere(venue)
					end

				end

			end

		end
	end

	def delete_comment
		vc = VenueComment.find_by_id(params[:id])
		bounty = vc.bounty
		if bounty != nil
			bounty.decrement!(:num_responses, 1)
		end
		vc.destroy
		render json: { success: true }
	end

	def report_comment
		venue_comment = VenueComment.find(params[:comment_id])
		fc = FlaggedComment.new
		fc.user_id = @user.id
		fc.message = params[:message]
		fc.venue_comment_id = venue_comment.id
		fc.save
		render json: fc
	end

	def get_comments
		@venue = Venue.find_by_id(params[:venue_id])
		@user = User.find_by_authentication_token(params[:auth_token])
		if not @venue
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue not found"] } }, :status => :not_found
		else
			@venue.delay.view(@user.id)
			@venue.delay.increment!(:page_views, 1)
			live_comments = @venue.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY' AND user_id IS NOT NULL").includes(:user).order('id desc')
			@comments = live_comments.page(params[:page]).per(5)
		end
	end

	def mark_comment_as_viewed
		@comment = VenueComment.find_by_id_and_venue_id(params[:post_id], params[:venue_id])

		#consider is used for Lumen calculation. Initially it is set to 2 for comments with no views and then is
		#updated to the true value (1 or 0) for a particular comment after a view (comments with no views aren't considered
		#for Lumen calcuation by default)

		if (@comment.is_viewed?(@user) == false) #and (@comment.user_id != @user.id)
			poster = @comment.user
			poster.update_total_views
			@comment.update_views
			if poster_id != @user.id
				@comment.calculate_adj_view
				if @comment.consider? == 1 
					poster.delay.update_lumens_after_view(@comment)
				end
			end
		end

		if @comment.present?
				comment_view = CommentView.new
				comment_view.user = @user
				comment_view.venue_comment = @comment
				comment_view.save
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue / Post not found"] } }, :status => :not_found
			return
		end
	end

	def search
		@user = User.find_by_authentication_token(params[:auth_token])
		if params[:group_id].present? and not params[:q].present?
			@group = Group.find_by_id(params[:group_id])
			if @group
				render json: @group.venues_with_user_who_added
			else
				render json: { error: { code: ERROR_NOT_FOUND, messages: ["Group with id #{params[:group_id]} not found"] } }, status: :not_found
			end
		else

			#I am aware this approach is Muppet, need to update later 
			venue0 = Venue.fetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude], params[:pin_drop])

			venue1 = Venue.fetch(params[:name1], params[:formatted_address1], params[:city1], params[:state1], params[:country1], params[:postal_code1], params[:phone_number1], params[:latitude1], params[:longitude1], params[:pin_drop])
			venue2 = Venue.fetch(params[:name2], params[:formatted_address2], params[:city2], params[:state2], params[:country2], params[:postal_code2], params[:phone_number2], params[:latitude2], params[:longitude2], params[:pin_drop])
			venue3 = Venue.fetch(params[:name3], params[:formatted_address3], params[:city3], params[:state3], params[:country3], params[:postal_code3], params[:phone_number3], params[:latitude3], params[:longitude3], params[:pin_drop])
			venue4 = Venue.fetch(params[:name4], params[:formatted_address4], params[:city4], params[:state4], params[:country4], params[:postal_code4], params[:phone_number4], params[:latitude4], params[:longitude4], params[:pin_drop])
			venue5 = Venue.fetch(params[:name5], params[:formatted_address5], params[:city5], params[:state5], params[:country5], params[:postal_code5], params[:phone_number5], params[:latitude5], params[:longitude5], params[:pin_drop])
			venue6 = Venue.fetch(params[:name6], params[:formatted_address6], params[:city6], params[:state6], params[:country6], params[:postal_code6], params[:phone_number6], params[:latitude6], params[:longitude6], params[:pin_drop])
			venue7 = Venue.fetch(params[:name7], params[:formatted_address7], params[:city7], params[:state7], params[:country7], params[:postal_code7], params[:phone_number7], params[:latitude7], params[:longitude7], params[:pin_drop])
			venue8 = Venue.fetch(params[:name8], params[:formatted_address8], params[:city8], params[:state8], params[:country8], params[:postal_code8], params[:phone_number8], params[:latitude8], params[:longitude8], params[:pin_drop])
			venue9 = Venue.fetch(params[:name9], params[:formatted_address9], params[:city9], params[:state9], params[:country9], params[:postal_code9], params[:phone_number9], params[:latitude9], params[:longitude9], params[:pin_drop])
			venue10 = Venue.fetch(params[:name10], params[:formatted_address10], params[:city10], params[:state10], params[:country10], params[:postal_code10], params[:phone_number10], params[:latitude10], params[:longitude10], params[:pin_drop])

			@venues = [venue0, venue1, venue2, venue3, venue4, venue5, venue6, venue7, venue8, venue9, venue10].compact

			#for the search of a place to add to a Placelist we check if the place is already in the place list
			@group_id = params[:g_id]
			#@venues = Venue.fetch_venues('search', params[:q], params[:latitude], params[:longitude], params[:radius], params[:timewalk_start_time], params[:timewalk_end_time], params[:group_id], @user)
			render 'search.json.jbuilder'
		end
	end

	def get_suggested_venues
		@user = User.find_by_authentication_token(params[:auth_token])
		@suggestions = Venue.near_locations(params[:latitude], params[:longitude])
		render 'get_suggested_venues.json.jbuilder'
	end

	def rate_venue
		venue = Venue.find(params[:venue_id])
		@venue_rating = VenueRating.new(params.permit(:rating))
		@venue_rating.venue = venue
		@venue_rating.user = @user

		if @venue_rating.save
			render json: venue
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: @venue_rating.errors.full_messages } }, status: :unprocessable_entity
		end
	end

	def vote
		vote_value = params[:rating] > LytitBar.instance.position ? 1 : -1

		venue = Venue.find(params[:venue_id])
		rating = venue.rating
		v = LytitVote.new(:value => vote_value, :venue_id => params[:venue_id], :user_id => @user.id, :venue_rating => rating ? rating : 0, 
											:prime => venue.get_k, :raw_value => params[:rating])

		if v.save
			venue.delay.account_new_vote(vote_value, v.id)
			
			if venue.has_been_voted_at == false
				venue.has_been_voted_at = true
				venue.save
			end

			if LytSphere.where("venue_id = ?", params[:venue_id]).count == 0
				lyt_sphere = LytSphere.new(:venue_id => venue.id, :sphere => venue.l_sphere)
				lyt_sphere.save
			end

			render json: {"registered_vote" => vote_value, "venue_id" => params[:venue_id]}, status: :ok
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: v.errors.full_messages } }, status: :unprocessable_entity
		end
	end


	private

	def venue
		@venue ||= Venue.find(params[:venue_id])
	end

	def venue_comment_params
		params.permit(:comment, :media_type, :media_url, :session)
	end
end
