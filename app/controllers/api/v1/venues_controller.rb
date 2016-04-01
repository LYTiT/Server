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

	def venue_primer
		render json: { success: true }
	end

	def cluster_primer
		venue_ids = params[:cluster_venue_ids].split(',').map(&:to_i)
		render json: { success: true }
	end

	def request_moment
		mr = MomentRequest.create!(:user_id => params[:user_id], :venue_id => params[:venue_id])
		if mr
			render json: { success: true }
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Moment Request Failed"] } }, :status => :not_found
		end
	end

	def delete_moment_request
		mr = MomentRequest.find_by_id(params[:moment_request_id])
		if mr.delete
			render json: { success: true }
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Moment Request Deletion Failed"] } }, :status => :not_found
		end
	end

	def post_comment
		if params[:venue_id] != nil
			venue = Venue.find_by_id(params[:venue_id])
		else
			venue = Venue.fetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude])
		end

		user = User.find_by_authentication_token(params[:auth_token])

		if params[:media_type] == "image"
			vc = VenueComment.create!(:venue_id => venue.id, :user_id => user.id, :thirdparty_username => user.name, :media_type => "image", :media_dimensions => params[:media_dimensions], :image_url_2 => "small-"+params[:image_url_3],
				:image_url_3 => params[:image_url_3], :comment => params[:comment], :time_wrapper => Time.now, :content_origin => "lytit", :adjusted_sort_position => (Time.now+30.minutes).to_i) 
		else
			vc = VenueComment.create!(:venue_id => venue.id, :user_id => user.id, :thirdparty_username => user.name, :media_type => "video", :media_dimensions => params[:media_dimensions],
				:video_url_3 => params[:video_url_3], :comment => params[:comment], :time_wrapper => Time.now, :content_origin => "lytit", :adjusted_sort_position => (Time.now+30.minutes).to_i)
		end

		if vc
			venue.delay(:priority => -4).calibrate_after_lytit_post(vc)		
			render json: vc
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: vc.errors.full_messages } }, status: :unprocessable_entity
		end
	end


	def get_comments_feed
		page = params[:page].to_i
		if params[:venue_id]
			@venue = Venue.find_by_id(params[:venue_id])
		else
			@venue = Venue.fetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude])
		end
		@comments = @venue.content_feed_page(page)
	end


	#for version 1.1.0
	def get_comments
		num_elements_per_page = 10
		page = params[:page].to_i
		venue_ids = params[:cluster_venue_ids].split(',').map(&:to_i)

		if venue_ids.count == 1
			@venue = Venue.find_by_id(venue_ids.first)
			@venue_id = @venue.id
			@venue.delay.account_page_view(@user.id)

			if params[:meta_query] != nil
				@comments = VenueComment.where("venue_id = ?", @venue.id).meta_search(params[:meta_query]).order("time_wrapper DESC").page(params[:page]).per(10)#VenueComment.meta_search_results(@venue.id, params[:meta_query]).page(params[:page]).per(10)
				render 'pure_comments.json.jbuilder'
			else						
				instagrams_cache_key = "venue/#{venue_ids.first}/latest_instagrams"
				latest_venue_instagrams = Rails.cache.fetch(instagrams_cache_key)
				if latest_venue_instagrams == nil
					latest_venue_instagrams = @venue.update_comments
					#in version 1.1.0 the next page is not pulled if there is less than 6 elements returned on the previous page.
					#To resolve this we introduce this hack to backfill the last element enough time so that the size of the array is
					#6. These dupes are then filtered out on the front.
					if (latest_venue_instagrams.length%num_elements_per_page) != 0 && latest_venue_instagrams.last != nil
						if latest_venue_instagrams.length < num_elements_per_page
							(num_elements_per_page - latest_venue_instagrams.length).times{latest_venue_instagrams <<  latest_venue_instagrams.last}
						else
							(num_elements_per_page - (latest_venue_instagrams.length%num_elements_per_page)).times{latest_venue_instagrams <<  latest_venue_instagrams.last}						
						end
						Rails.cache.write(instagrams_cache_key, latest_venue_instagrams, :expires_in => 10.minutes)
					else						
						Rails.cache.write(instagrams_cache_key, latest_venue_instagrams, :expires_in => 10.minutes)
					end
				end

				latest_instagrams_count = latest_venue_instagrams.length

				@view_cache_key = "venue/#{venue_ids.first}/comments/page#{params[:page]}/view"
				if (latest_instagrams_count > 0) && (num_elements_per_page*(page-1) < latest_instagrams_count)
					start_index = (page-1)*(num_elements_per_page)
					end_index = start_index+(num_elements_per_page-1)
					@comments = latest_venue_instagrams[start_index..end_index]
					render 'dirty_comments.json.jbuilder'
				else
					offset_page = page - (latest_instagrams_count.to_f/num_elements_per_page.to_f).ceil
					vc_cache_key = "venue/#{venue_ids.first}/comments/page#{params[:page]}"
					@comments = Rails.cache.fetch(vc_cache_key, :expires_in => 10.minutes) do
						VenueComment.where("venue_id = ? AND created_at <= ?", @venue_id, Time.now-10.minutes).order("time_wrapper DESC").limit(10).offset((offset_page-1)*10)
					end
					if params[:version] == "1.1.0"
						render 'pure_comments_1.1.0_patch.json.jbuilder'
					else
						render 'pure_comments.json.jbuilder'
					end
				end
			end
		else
			cache_key = "cluster/cluster_#{venue_ids.length}_#{params[:cluster_latitude]},#{params[:cluster_longitude]}/comments/page#{params[:page]}"
			#@comments = VenueComment.joins(:venue).where("venues.id in (#{params[:cluster_venue_ids]})").order("time_wrapper DESC").page(page).per(10)
			@comments = VenueComment.where("venue_id IN (?)", venue_ids).order("time_wrapper desc").page(page).per(10)
			@venue_id = nil
			if params[:version] == "1.1.0"
				render 'pure_comments_1.1.0_patch.json.jbuilder'
			else
				render 'pure_comments.json.jbuilder'
			end
		end	
	end

	def get_comments_implicitly
		num_elements_per_page = 10
		page = params[:page].to_i

		if params[:country] != nil
			@venue = Venue.fetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude])
			#Venue.fetch(params["name"], params["formatted_address"], params["city"], params["state"], params["country"], params["postal_code"], params["phone_number"], params["latitude"], params["longitude"])
		else
			@venue = Venue.fetch_venues_for_instagram_pull(params[:name], params[:latitude].to_f, params[:longitude].to_f, params[:instagram_location_id], nil)
		end
		#@venue.delay.account_page_view(@user.id)		

		instagrams_cache_key = "venue/#{@venue.id}/latest_instagrams"

		latest_venue_instagrams = Rails.cache.fetch(instagrams_cache_key)
		if latest_venue_instagrams == nil
			latest_venue_instagrams = @venue.update_comments
			#in version 1.1.0 the next page is not pulled if there is less than 6 elements returned on the previous page.
			#To resolve this we introduce this hack to backfill the last element enough time so that the size of the array is
			#6. These dupes are then filtered out on the front.
			if (latest_venue_instagrams.length%num_elements_per_page) != 0 && latest_venue_instagrams.last != nil
				if latest_venue_instagrams.length < num_elements_per_page
					(num_elements_per_page - latest_venue_instagrams.length).times{latest_venue_instagrams <<  latest_venue_instagrams.last}
				else
					(num_elements_per_page - (latest_venue_instagrams.length%num_elements_per_page)).times{latest_venue_instagrams <<  latest_venue_instagrams.last}						
				end
				Rails.cache.write(instagrams_cache_key, latest_venue_instagrams, :expires_in => 10.minutes)
			else						
				Rails.cache.write(instagrams_cache_key, latest_venue_instagrams, :expires_in => 10.minutes)
			end
		end
		latest_instagrams_count = latest_venue_instagrams.length

		@view_cache_key = "venue/#{@venue.id}/comments/page#{params[:page]}/view"
		if (latest_instagrams_count > 0) && (num_elements_per_page*(page-1) < latest_instagrams_count)
			start_index = (page-1)*(num_elements_per_page)
			end_index = start_index+(num_elements_per_page-1)
			@comments = latest_venue_instagrams[start_index..end_index]
			@venue_id = @venue.id
			render 'dirty_comments.json.jbuilder'
		else
			offset_page = page - (latest_instagrams_count.to_f/num_elements_per_page.to_f).ceil
			vc_cache_key = "venue/#{@venue.id}/comments/page#{params[:page]}"
			@comments = Rails.cache.fetch(vc_cache_key, :expires_in => 10.minutes) do
				VenueComment.where("venue_id = ? AND created_at <= ?", @venue.id, Time.now-10.minutes).order("time_wrapper DESC").limit(10).offset((offset_page-1)*10)
			end
			@venue_id = @venue.id
			if params[:version] == "1.1.0"
				render 'pure_comments_1.1.0_patch.json.jbuilder'
			else
				render 'pure_comments.json.jbuilder'
			end
		end

	end	

	def get_venue_feeds
		@user = User.find_by_authentication_token(params[:auth_token])
		@feeds = Feed.feeds_in_venue(params[:venue_id]).page(params[:page]).per(10)
	end

	def get_cluster_feeds
		@user = User.find_by_authentication_token(params[:auth_token])
		@feeds = Feed.feeds_in_cluster(params[:cluster_venue_ids]).page(params[:page]).per(10)
	end
		
	def get_tweets
		venue_ids = params[:cluster_venue_ids].split(',')
		cluster_lat = params[:cluster_latitude]
		cluster_long =  params[:cluster_longitude]
		zoom_level = params[:zoom_level]
		map_scale = params[:map_scale]

		
		if venue_ids.count == 1
			@venue = Venue.find_by_id(venue_ids.first)		
			cache_key = "venue/#{venue_ids.first}/tweets/page#{params[:page]}"
			
			#venue_tweets = @venue.venue_twitter_tweets
			#@tweets = venue_tweets.page(params[:page]).per(10)
		else
			cache_key = "cluster/cluster_#{venue_ids.length}_#{params[:cluster_latitude]},#{params[:cluster_longitude]}/tweets/page#{params[:page]}"	
			#cluster_tweets = Venue.cluster_twitter_tweets(cluster_lat, cluster_long, zoom_level, map_scale, params[:cluster_venue_ids])
			#@tweets = cluster_tweets.page(params[:page]).per(10)
		end

		@tweets = Rails.cache.fetch(cache_key, :expires_in => 3.minutes) do
			if venue_ids.count == 1
				@venue.venue_twitter_tweets.limit(10).offset((params[:page].to_i-1)*10)
			else
				Venue.cluster_twitter_tweets(cluster_lat, cluster_long, zoom_level, map_scale, params[:cluster_venue_ids]).offset((params[:page].to_i-1)*10)
			end
		end

	end

	def get_surrounding_tweets
		venue_ids = params[:cluster_venue_ids].split(',')
		lat = params[:cluster_latitude]
		long =  params[:cluster_longitude]
		zoom_level = params[:zoom_level]
		map_scale = params[:map_scale]
		fresh_pull = params[:fresh_pull]

		@user = User.find_by_authentication_token(params[:auth_token])

		if fresh_pull == "0"
			surrounding_tweets = Rails.cache.fetch("surrounding_tweets/#{@user.id}", :expires_in => 5.minutes) do
				Venue.surrounding_twitter_tweets(lat, long, params[:cluster_venue_ids])
			end
		else
			begin
				Rails.cache.delete("surrounding_tweets/#{@user.id}")
			rescue
				puts "No cache present to delete"
			end
			surrounding_tweets = Venue.surrounding_twitter_tweets(lat, long, params[:cluster_venue_ids])
		end
		
		@tweets = Kaminari.paginate_array(surrounding_tweets).page(params[:page]).per(10)
	end

	def refresh_map_view
		Venue.delay(:priority => -2).surrounding_area_instagram_pull(params[:latitude], params[:longitude]) #this is to handle places not near a vortex
		cache_key = "lyt_map"
		@view_cache_key = cache_key+"/view"
		@venues = Rails.cache.fetch(cache_key, :expires_in => 5.minutes) do
			Venue.where("color_rating > -1.0").to_a
		end
		render 'display.json.jbuilder'
	end

	def refresh_map_view_by_parts
		if params[:user_city] != nil
			city = params[:user_city]
		else
			city = InstagramVortex.within(20, :units => :kms, :origin => [lat, long]).order("id ASC").first.city rescue "New York"
		end

		@view_cache_key = "#{city}/lyt_map/view/page_"+params[:page].to_s

		if Rails.cache.exist?(@view_cache_key) == true
			render 'display_by_parts.json.jbuilder'
		else
			Rails.cache.write(@view_cache_key, Time.now, :expires_in => 10.minutes)
			city_cache_key = "#{city}/lyt_map/page_#{params[:page]}"
			page = params[:page].to_i
			if page == 1
				num_page_entries = 300
			else
				num_page_entries = 500
			end

			@venues = Rails.cache.fetch(city_cache_key, :expires_in => 10.minutes) do
				venues = Venue.close_to(params[:latitude], params[:longitude], 5000).where("color_rating > -1.0").order("id desc").page(page).per(num_page_entries).to_a
				if venues.length == 0 
					Venue.far_from(params[:latitude], params[:longitude], 5000).where("color_rating > -1.0").order("id desc").page(page).per(num_page_entries)
				else
					venues
				end
			end
			p "------------------------------------ Number of venues: #{@venues.count} / Cache key: #{@view_cache_key}"
			render 'display_by_parts.json.jbuilder'
		end
	end

	def search
		@user = User.find_by_authentication_token(params[:auth_token])

		if params[:instagram_location_id] == nil
			venue = Venue.fetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude])
			@venues = [venue]
		else
			@venues =[Venue.fetch_venues_for_instagram_pull(params[:name], params[:latitude], params[:longitude], params[:instagram_location_id], nil)]
		end

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

		@venues = Venue.direct_fetch(query, position_lat, position_long, ne_lat, ne_long, sw_lat, sw_long)

		render 'search.json.jbuilder'
	end

	def meta_fetch
		position_lat = params[:latitude]
		position_long = params[:longitude]

		ne_lat = params[:ne_latitude]
		ne_long = params[:ne_longitude]
		sw_lat = params[:sw_latitude]
		sw_long = params[:sw_longitude]

		query = params[:q]
		@venues = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ?", sw_lat, ne_lat, sw_long, ne_long).meta_search(query).limit(20)
		render 'search.json.jbuilder'
	end

	def get_venue_contexts
		@venue = Venue.find_by_id(params[:venue_id])			
	end

	def get_cluster_contexts
		@contexts = MetaData.cluster_top_meta_tags(params[:cluster_venue_ids])
		@key = "contexts/cluster/#{params[:cluster_venue_ids].first(10)}_#{params[:cluster_venue_ids].length}"
		render 'get_cluster_contexts.json.jbuilder'
	end

	def explore_venues
		previous_venue_ids = params[:previous_venue_ids]
		if previous_venue_ids == nil
			previous_venue_ids = []
		else
			previous_venue_ids = previous_venue_ids.split(',').map(&:to_i)
		end
		@venue = Venue.discover(params[:proximity], params[:previous_venue_ids], params[:latitude], params[:longitude])
	end

	def get_trending_venues_for_user_list_feed
		@venues = Venue.trending_venues_for_user(params[:latitude], params[:longitude])
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

		@posts = VenueComment.where("venue_id IN (?)", venue_ids).order("id DESC LIMIT 4")
		@meta = MetaData.where("venue_id IN (?)", venue_ids).order("relevance_score DESC LIMIT 5")
	end

	def get_surrounding_feed_for_user
		lat = params[:latitude]
		long = params[:longitude]
		venue_ids = params[:venue_ids]

		fresh_pull = params[:fresh_pull]

		@user = User.find_by_authentication_token(params[:auth_token])

		if fresh_pull == "0"
			surrounding_posts = Rails.cache.fetch("surrounding_posts/#{@user.id}", :expires_in => 5.minutes) do
				Venue.surrounding_feed(lat, long, venue_ids)
			end
		else
			begin
				Rails.cache.delete("surrounding_posts/#{@user.id}")
			rescue
				puts "No cache present to delete"
			end
			surrounding_posts = Rails.cache.fetch("surrounding_posts/#{@user.id}", :expires_in => 5.minutes) do
				Venue.surrounding_feed(lat, long, venue_ids)
			end
		end
		
		@posts = Kaminari.paginate_array(surrounding_posts).page(params[:page]).per(10)
	end

	def check_vortex_proximity
		InstagramVortex.check_nearby_vortex_existence(params[:latitude], params[:longitude])
		render json: { success: true }
	end

	def add_to_favorites
		venue = Venue.find_by_id(params[:venue_id])
		venue_details_hash = venue.details_hash
		fv = FavoriteVenue.create!(:venue_id => venue.id, :venue_name => venue.name, :user_id => params[:user_id], :venue_details => venue_details_hash)

		if fv
			render json: fv
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue Not Favorited"] } }, :status => :not_found
		end
	end

	def remove_from_favorites
		if params[:favorite_venue_id]
			fv = FavoriteVenue.find_by_id(params[:favorite_venue_id])
		else
			fv = FavoriteVenue.where("venue_id = ? AND user_id = ?", params[:venue_id], params[:user_id]).first
		end

		if fv.delete
			render json: { success: true }
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Failed to Remove From Favorites"] } }, :status => :not_found
		end
	end

	def get_events
		@events = Event.where("venue_id = ?", params[:venue_id])
	end


	private

	def venue
		@venue ||= Venue.find(params[:venue_id])
	end

	def venue_comment_params
		params.permit(:comment, :media_type, :media_url, :session)
	end
end
