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
					
					if (part.session == session) && (incoming_part_type == "text" || part.media_type == "text")
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
							if part.media_type == "image"
								@comment.image_url_1 = part.media_url
							else
								@comment.video_url_1 = part.media_url
							end
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

				#if (@comment.media_type == 'text' and @comment.consider? == 1)
				#	if assign_lumens == true and @comment.comment.split.count >= 5 # far from science but we assume that if a Venue Comment is text it should have at least 5 words to be considered 'useful'
				#		@user.update_lumens_after_text(@comment.id)
				#	end
				#end

				#if (@comment.media_type != 'text' and @comment.consider? == 1)
				#	@user.update_lumens_after_media(@comment)
				#end

				#if a hot venue and valid bonus post assign user bonus lumens
				#if params[:bonus_lumens] != nil
				#	@user.account_new_bonus_lumens(params[:bonus_lumens])
				#end

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
				#@comment.extract_venue_comment_meta_data
				venue.feeds.delay.update_all(new_media_present: true)
				venue.delay.update_rating()
			end

		end
	end

	def delete_comment
		vc = VenueComment.find_by_id(params[:id])
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

	def get_comments_of_a_venue
		v = [params[:venue_id]]
		@venue = Venue.find_by_id(params[:venue_id])
		@venue.account_page_view
		@venue.instagram_pull_check
		live_comments = VenueComment.get_comments_for_cluster(v)
		@comments = live_comments.page(params[:page]).per(10)
		render 'get_comments.json.jbuilder'
	end

	def get_comments
		if params[:feed_id] == nil
			expires_in 3.minutes, :public => true
		else
			@user = User.find_by_authentication_token(params[:auth_token])
			feeduser = FeedUser.where("user_id = ? AND feed_id = ?", @user.id, params[:feed_id]).first
			if feeduser != nil
				feeduser.update_columns(last_visit: Time.now)
			end
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
			@comments = live_comments.page(params[:page]).per(10)
		end
	end

	def get_tweets
		venue_ids = params[:cluster_venue_ids].split(',')
		cluster_lat = params[:cluster_latitude]
		cluster_long =  params[:cluster_longitude]
		zoom_level = params[:zoom_level]
		map_scale = params[:map_scale]

		if params[:feed_id] == nil
			if venue_ids.count == 1
				@venue = Venue.find_by_id(venue_ids.first)
				venue_tweets = Tweet.where("venue_id = ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", @venue.id).order("timestamp DESC").order("popularity_score DESC")
				@tweets = venue_tweets.page(params[:page]).per(10)
			else
				radius = Venue.meters_to_miles(map_scale.to_f/2.0)
				cluster = ClusterTracker.check_existence(cluster_lat, cluster_long, zoom_level)
				cluster_tweets = Tweet.where("venue_id IN (?) OR (ACOS(least(1,COS(RADIANS(#{cluster_lat}))*COS(RADIANS(#{cluster_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{cluster_lat}))*SIN(RADIANS(#{cluster_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{cluster_lat}))*SIN(RADIANS(latitude))))*3963.1899999999996) 
          <= #{radius} AND associated_zoomlevel <= ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", venue_ids, zoom_level).order("timestamp DESC").order("popularity_score DESC")
				@tweets = cluster_tweets.page(params[:page]).per(10)
			end
		else
			@feed = Feed.find_by_id(params[:feed_id])
			feed_tweets = @feed.venue_tweets
			@tweets = feed_tweets.page(params[:page]).per(10)
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
		Venue.delay.instagram_content_pull(params[:latitude], params[:longitude])
		@venues = Venue.where("color_rating > -1.0").order("color_rating desc")
		render 'display.json.jbuilder'
	end

	def refresh_map_view_by_parts
		lat = params[:latitude] || 40.741140
		long = params[:longitude] || -73.981917

		if params[:page] == 1
			num_page_entries = 500
		else
			num_page_entries = 1000
		end

		venues = Kaminari.paginate_array(Venue.all.where("color_rating > -1.0").order("(ACOS(least(1,COS(RADIANS(#{lat}))*COS(RADIANS(#{long}))*COS(RADIANS(venues.latitude))*COS(RADIANS(venues.longitude))+COS(RADIANS(#{lat}))*SIN(RADIANS(#{long}))*COS(RADIANS(venues.latitude))*SIN(RADIANS(venues.longitude))+SIN(RADIANS(#{lat}))*SIN(RADIANS(venues.latitude))))*3963.1899999999996) ASC"))
		@venues = venues.page(params[:page]).per(num_page_entries)
		render 'display_by_parts.json.jbuilder'
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

	def direct_fetch
		position_lat = params[:latitude]
		position_long = params[:longitude]

		ne_lat = params[:ne_latitude]
		ne_long = params[:ne_longitude]
		sw_lat = params[:sw_latitude]
		sw_long = params[:sw_longitude]

		query = params[:q]

		@venues = Venue.direct_fetch(query, position_lat, position_long, ne_lat, ne_long, sw_lat, sw_long).to_a

		render 'search.json.jbuilder'
	end

	def get_suggested_venues
		@user = User.find_by_authentication_token(params[:auth_token])
		@suggestions = Venue.near_locations(params[:latitude], params[:longitude])
		render 'get_suggested_venues.json.jbuilder'
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

		if query.length > 2
			num_page_entries = 12
			page = params[:page].to_i

			crude_results = VenueComment.meta_search(query, lat, long, sw_lat, sw_long, ne_lat, ne_long)
			page_results = crude_results[ (page-1)*num_page_entries .. (page-1)*num_page_entries+(num_page_entries-1) ]

			previous_results = [params[:previous_id_1], params[:previous_id_2], params[:previous_id_3], params[:previous_id_4], params[:previous_id_5], params[:previous_id_6], params[:previous_id_7], params[:previous_id_8], params[:previous_id_9], params[:previous_id_10], params[:previous_id_11], params[:previous_id_12], params[:previous_id_13], params[:previous_id_14], params[:previous_id_15], params[:previous_id_16], params[:previous_id_17], params[:previous_id_18], params[:previous_id_19], params[:previous_id_20], params[:previous_id_21], params[:previous_id_22], params[:previous_id_23], params[:previous_id_24], params[:previous_id_25], params[:previous_id_26], params[:previous_id_27], params[:previous_id_28], params[:previous_id_29], params[:previous_id_30], params[:previous_id_31], params[:previous_id_32], params[:previous_id_33], params[:previous_id_34], params[:previous_id_35], params[:previous_id_36]]

			if page_results != nil
				for result in page_results
					if result != nil and (result.meta_search_sanity_check(query) == false || previous_results.include?(result.id.to_s) == true)
						page_results.delete(result)
					end
				end

				if page_results.count != num_page_entries
					pos = page * num_page_entries
					while (page_results.count < num_page_entries && pos < crude_results.count) do
						filler = crude_results[pos]
						if filler != nil and (filler.meta_search_sanity_check(query) == true && previous_results.include?(filler.id.to_s) == false)
							page_results << filler
						end
						pos = pos + 1
					end
				end
			end

			crude_results_paginated = Kaminari.paginate_array(crude_results)
			@page_tracker = crude_results_paginated.page(page).per(num_page_entries)
			@comments = page_results
		else
			@comments = nil
		end
	end

	def get_trending_venues 
		@venues = Rails.cache.fetch(:get_trending_venues, :expires_in => 5.minutes) do
			Venue.where("trend_position IS NOT NULL").order("trend_position ASC limit 10").includes(:venue_comments)
		end
	end

	def get_trending_venues_details
		@venues = Rails.cache.fetch(:get_trending_venues, :expires_in => 5.minutes) do
			Venue.where("trend_position IS NOT NULL").order("trend_position ASC limit 10").includes(:venue_comments)
		end		
	end

	def get_contexts
		#Hanlding both for individual venue and clusters.
		if params[:cluster_venue_ids] != nil
			@contexts = MetaData.cluster_top_meta_tags(params[:cluster_venue_ids])
			render 'get_cluster_contexts.json.jbuilder'
		else
			@venue = Venue.find_by_id(params[:venue_id])
			@contexts = @venue.meta_datas.order("relevance_score DESC LIMIT 5")
			render 'get_contexts.json.jbuilder'
		end
	end

	def explore_venues
		user_lat = params[:latitude]
		user_long = params[:longitude]
		if params[:past_venues].length == 0
			past_results = ["0"]
		else
			past_results = params[:past_venues].split(",")
		end
		nearby_radius = 2000 * 0.000621371 #meters to miles

		if params[:proximity] == "nearby"
			@venues = Venue.where("(ACOS(least(1,COS(RADIANS(#{user_lat}))*COS(RADIANS(#{user_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{user_lat}))*SIN(RADIANS(#{user_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{user_lat}))*SIN(RADIANS(latitude))))*3963.1899999999996) 
        <= #{nearby_radius} AND id NOT IN (?)", past_results).includes(:venue_comments, :meta_datas).order("popularity_rank DESC LIMIT 5")
		elsif params[:proximity] == "far"
			@venues = Venue.where("(ACOS(least(1,COS(RADIANS(#{user_lat}))*COS(RADIANS(#{user_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{user_lat}))*SIN(RADIANS(#{user_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{user_lat}))*SIN(RADIANS(latitude))))*3963.1899999999996) 
        > #{nearby_radius} AND id NOT IN (?)", past_results).includes(:venue_comments, :meta_datas).order("popularity_rank DESC LIMIT 5")
		else
			nearby_venues = Venue.where("(ACOS(least(1,COS(RADIANS(#{user_lat}))*COS(RADIANS(#{user_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{user_lat}))*SIN(RADIANS(#{user_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{user_lat}))*SIN(RADIANS(latitude))))*3963.1899999999996) 
        <= #{nearby_radius} AND id NOT IN (?)", past_results).includes(:venue_comments, :meta_datas).order("popularity_rank DESC LIMIT 3")
			far_venues = Venue.where("(ACOS(least(1,COS(RADIANS(#{user_lat}))*COS(RADIANS(#{user_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{user_lat}))*SIN(RADIANS(#{user_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{user_lat}))*SIN(RADIANS(latitude))))*3963.1899999999996) 
        > #{nearby_radius} AND id NOT IN (?)", past_results).includes(:venue_comments, :meta_datas).order("popularity_rank DESC LIMIT 3")
			@venues = (nearby_venues << far_venues).flatten
		end			
	end

	def get_latest_tweet
		venue_ids = params[:cluster_venue_ids].split(",")
		cluster_lat = params[:cluster_latitude]
		cluster_long =  params[:cluster_longitude]
		zoom_level = params[:zoom_level]
		map_scale = params[:map_scale]

		radius = 0.1

		if venue_ids.count == 1
			venue = Venue.find_by_id(venue_ids.first)
			@tweet = Tweet.where("venue_id = ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", venue.id).order("timestamp DESC").order("popularity_score DESC LIMIT 1")[0]
			venue.delay.pull_twitter_tweets
		else
			cluster = ClusterTracker.check_existence(cluster_lat, cluster_long, zoom_level)
			@tweet = Tweet.where("venue_id IN (?) OR (ACOS(least(1,COS(RADIANS(#{cluster_lat}))*COS(RADIANS(#{cluster_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{cluster_lat}))*SIN(RADIANS(#{cluster_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{cluster_lat}))*SIN(RADIANS(latitude))))*3963.1899999999996) 
          <= #{radius} AND associated_zoomlevel <= ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", venue_ids, zoom_level).order("timestamp DESC").order("popularity_score DESC LIMIT 1")[0]
			Venue.delay.cluster_twitter_tweets(cluster_lat, cluster_long, zoom_level, map_scale, cluster, params[:cluster_venue_ids])
		end
	end

	def get_quick_venue_overview
		@venue = Venue.find_by_id(params[:venue_id])
	end

	def get_quick_cluster_overview
		venue_ids = params[:cluster_venue_ids].split(',')
		cluster_lat = params[:cluster_latitude]
		cluster_long =  params[:cluster_longitude]
		zoom_level = params[:zoom_level]
		map_scale = params[:map_scale]

		cluster = ClusterTracker.check_existence(cluster_lat, cluster_long, zoom_level)

		@posts = VenueComment.where("venue_id IN (?)", venue_ids).order("id DESC LIMIT 4")
		@meta = MetaData.where("venue_id IN (?)", venue_ids).order("id DESC LIMIT 5")
	end

	def get_surrounding_feed_for_user
		lat = params[:latitude]
		long = params[:longitude]
		venue_ids = params[:venue_ids].split(',')

		meter_radius = 100
		
		if 3 > 4#venue_ids.first != nil
			@venues = Kaminari.paginate_array(Venue.where("id IN (?)", venue_ids).includes(:venue_comments).to_a).page(params[:page]).per(2)
		else
			#make instagram pull 
			surrounding_instagrams = Instagram.media_search(lat, long, :distance => meter_radius, :count => 20, :min_timestamp => (Time.now-24.hours).to_time.to_i)

			for instagram in surrounding_instagrams
				VenueComment.convert_instagram_to_vc(instagram, nil, nil)
			end

			@venues = Kaminari.paginate_array(Venue.within(Venue.meters_to_miles(meter_radius.to_i), :origin => [lat, long]).where("latest_rating_update_time > ?", (Time.now - 10.minutes)).includes(:venue_comments).order('distance ASC')).page(params[:page]).per(2)
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
