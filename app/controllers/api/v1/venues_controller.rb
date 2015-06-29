class Api::V1::VenuesController < ApiBaseController

	skip_before_filter :set_user, only: [:search, :index]

	def show
		@user = User.find_by_authentication_token(params[:auth_token])
		@venue = Venue.find(params[:id])		
		venue = @venue.as_json(include: :venue_messages)

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

	#for a city, state, country in the venue page we return a bounty feed composed of bounties and claims instead of pure venue comments
	def get_area_bounty_feed
		@user = User.find_by_authentication_token(params[:auth_token])
		feed = Venue.area_bounty_feed(params[:venue_id])
		@area_feed = Kaminari.paginate_array(feed).page(params[:page]).per(10)
	end

	def add_comment
		parts_linked = false #becomes 'true' when Venue Comment is formed by two parts conjoining
		assign_lumens = false #in v3.0.0 posting by parts makes sure that lumens are not assigned for the creation of the text part of a media Venue Comment

		session = params[:session]		
		incoming_part_type = params[:venue_id] == 14002 ? "media" : "text" #we use the venue_id '14002' as a key to signal a posting by parts operation

		completion = false #add_comment method is completed either once a Venue Comment or a Temp Posting Housing object is created
		#temp housing venue handling
		if params[:venue_id] == 14002
			v_id = nil
			venue = nil
		else
			v_id = params[:venue_id]
			venue = Venue.find_by_id(params[:venue_id])
		end

		if session != 0 #simple text comments have a session id = 0 and do not need to be seperated into parts
			posting_parts = @user.temp_posting_housings.order('id ASC')

			if posting_parts.count == 0 #if no parts are housed there is nothing to link
				vc_part = TempPostingHousing.new(:user_id => @user.id, :venue_id => v_id, :media_type => params[:media_type], :media_url => params[:media_url], 
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
					vc_part = TempPostingHousing.new(:user_id => @user.id, :venue_id => v_id, :media_type => params[:media_type], :media_url => params[:media_url], 
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
				
				@comment.content_origin = "lytit"
				@comment.time_wrapper = Time.now
				@comment.save


				venue = @comment.venue
				venue.update_columns(latest_posted_comment_time: Time.now)

				if (@comment.media_type == 'text' and @comment.consider? == 1) and assign_lumens == true
					if @comment.comment.split.count >= 5 # far from science but we assume that if a Venue Comment is text it should have at least 5 words to be considered 'useful'
						@user.delay.update_lumens_after_text(@comment.id)
					end
				end

				if (@comment.media_type != 'text' and @comment.consider? == 1)
					@user.delay.update_lumens_after_media(@comment)
				end

				#If the Venue Comment is a Bounty response we update bounty_id field
				if params[:is_bounty_response] != nil
					@comment.is_response = true
					@comment.bounty_id = params[:is_bounty_response]
					b = Bounty.find_by_id(params[:is_bounty_response])
					b.response_received = true
					b.increment!(:num_responses, 1)
					#we keep track of the latest 10 responses for a bounty to display thumbnails in the bounty feed
					b.add_latest_response(@comment)
					bounty_housing_comment = VenueComment.where("user_id IS NULL AND bounty_id = ?", params[:is_bounty_response]).first
					bounty_housing_comment.update_columns(time_wrapper: Time.now)
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
													:prime => 0.0, :raw_value => 1.0, :time_wrapper => Time.now)

				if v.save
					venue.update_r_up_votes(Time.now)
            		venue.update_columns(latest_posted_comment_time: Time.now)

					if LytSphere.where("venue_id = ?", venue.id).count == 0
						LytSphere.delay.create_new_sphere(venue)
					end

				end
				@comment.extract_venue_comment_meta_data

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
		if FlaggedComment.where("user_id = ? AND venue_comment_id = ? AND message = ?", @user.id, params[:comment_id], params[:message]).any? == false
			venue_comment = VenueComment.find(params[:comment_id])
			fc = FlaggedComment.new
			fc.user_id = @user.id
			fc.message = params[:message]
			fc.venue_comment_id = venue_comment.id
			fc.save
			render json: fc
		end
	end

	def get_comments
		if params[:feed_id] != nil
			feed = Feed.find_by_id(params[:feed_id])
			feed.update_columns(latest_viewed_time: Time.now)
			feed.update_columns(new_media_present: false)
			feed.update_media
		end

		venue_ids = params[:cluster_venue_ids].split(',').map(&:to_i)
		if not venue_ids 
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue(s) not found"] } }, :status => :not_found
		else
			if venue_ids.count == 1 && params[:feed_id] == nil
				@venue = Venue.find_by_id(venue_ids.first)

				@venue.account_page_view
				@venue.instagram_pull_check
			end
			live_comments = VenueComment.get_comments_for_cluster(venue_ids)
			@comments = live_comments.page(params[:page]).per(25)
		end
	end

	def mark_comment_as_viewed
		@user = User.find_by_authentication_token(params[:auth_token])
		@comment = VenueComment.find_by_id(params[:post_id])

		#consider is used for Lumen calculation. Initially it is set to 2 for comments with no views and then is
		#updated to the true value (1 or 0) for a particular comment after a view (comments with no views aren't considered
		#for Lumen calcuation by default)

		if (@comment.is_viewed?(@user) == false) #and (@comment.user_id != @user.id)
			@comment.update_views
			poster = @comment.user
			if poster != nil
				poster.update_total_views
				if poster.id != @user.id
					@comment.calculate_adj_view
					if @comment.consider? == 1 
						poster.update_lumens_after_view(@comment)
					end
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

	def refresh_map_view
		@venues = Venue.where("color_rating > -1.0").order("color_rating desc")
		render 'display.json.jbuilder'
	end

	def search
		@user = User.find_by_authentication_token(params[:auth_token])

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

		#@venues = Venue.fetch_venues('search', params[:q], params[:latitude], params[:longitude], params[:radius], params[:timewalk_start_time], params[:timewalk_end_time], params[:group_id], @user)
		render 'search.json.jbuilder'
	end

	def meta_search
		lat = params[:latitude]
		long = params[:longitude]
		sw_lat = params[:sw_latitude]
		sw_long = params[:sw_longitude]
		ne_lat = params[:ne_latitude]
		ne_long = params[:ne_longitude]
		
		#Cleaning the search term
		query = params[:q].downcase.gsub(" ","").gsub(/[^0-9A-Za-z]/, '')
		junk_words = ["the", "their", "there", "yes", "you", "are", "when", "why", "what", "lets", "this", "got", "put", "such", "much", "ask", "with", "where", "each", "all", "from", "bad", "not", "for", "our"]
		junk_words.each{|word| query.gsub!(word, "")}

		#Plurals singularized for searching purposes (ie "dogs" returns the same things as "dog")
		if query.length > 3
			if (query.last(3) != "ies" && query.last(1) == "s") 
				query = query[0...-1]
			end
			if (query.last(3) == "ies")
				query = query[0...-3]
			end
		end
		@query = query
		results = Venue.meta_search(query, lat, long, sw_lat, sw_long, ne_lat, ne_long).to_a
		@venues = Kaminari.paginate_array(results).page(params[:page]).per(15)
	end

	def get_trending_venues
		@venues = Venue.where("popularity_rank IS NOT NULL").includes(:venue_comments).order("popularity_rank desc limit 10").to_a
		@venue_hash = Hash[@venues.map.with_index.to_a]
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
											:prime => 0, :raw_value => params[:rating])

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
