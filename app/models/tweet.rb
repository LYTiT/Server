class Tweet < ActiveRecord::Base
	acts_as_mappable :default_units => :kms,
	             :default_formula => :sphere,
	             :distance_field_name => :distance,
	             :lat_column_name => :latitude,
	             :lng_column_name => :longitude

	belongs_to :venue

    
	def partial
		{:twitter_user => {:name => self.author_name, :handle => self.handle, :profile_image_url => self.author_avatar, :twitter_id => self.author_id}, :id => self.id, :twitter_id => self.twitter_id, :tweet_text => self.tweet_text, :image_url_1 => self.image_url_1, :image_url_2 => self.image_url_2, :image_url_3 => self.image_url_3, :popularity_score => self.popularity_score, :created_at => self.timestamp}
	end

	def Tweet.set_daily_tweet_id
		lower_tweet_id_daily_bound = Tweet.where("timestamp > ?", Time.now - 24.hours).order("timestamp ASC").first.twitter_id
		LytitConstants.where("constant_name = ?", "daily_tweet_id").first.update_columns(big_value: lower_tweet_id_daily_bound)
		LytitConstants.where("constant_name = ?", "daily_tweet_id").first.touch
	end

	def self.popularity_score_calculation(followers_count, retweet_count, favorite_count)
	#we calculate the 'importance' of a tweet through a combination of retweet count as well as tweet user follower count considerations: [1/(e^(-alpha_factor * follower_count ^(beta_factor)) + 1) + retweet_count^(1/gamma_factor)]
	alpha_factor = 0.1
	beta_factor = 0.27
	gamma_factor = 5.0

	tweet_popularity_score = 1.0 / (Math::E ** (-alpha_factor.to_f * followers_count.to_f ** beta_factor) + 1.0) + retweet_count.to_f ** (1.0 / gamma_factor)      
	end

	def self.bulk_conversion(raw_tweets, v, cluster_lat, cluster_long, zoom_level, map_scale)
		if v != nil
			for raw_tweet in raw_tweets
				if Tweet.find_by_twitter_id(raw_tweet.id) == nil
					raw_tweet_text = raw_tweet.text.dup
					new_tweet = Tweet.create!(:twitter_id => raw_tweet.id, :tweet_text => raw_tweet_text, :image_url_1 => Tweet.implicit_image_url_1(raw_tweet), :image_url_2 => Tweet.implicit_image_url_2(raw_tweet), :image_url_3 => Tweet.implicit_image_url_3(raw_tweet), :author_id => raw_tweet.user.id, :handle => raw_tweet.user.screen_name, :author_name => raw_tweet.user.name, :author_avatar => raw_tweet.user.profile_image_url.to_s, :timestamp => raw_tweet.created_at, :from_cluster => false, :venue_id => v.id, :popularity_score => Tweet.popularity_score_calculation(raw_tweet.user.followers_count, raw_tweet.retweet_count, raw_tweet.favorite_count))
					VenueComment.create!(:entry_type => "tweet", :venue_id => v.id, :venue_details => v.partial, :tweet => new_tweet.partial, :adjusted_sort_position => new_tweet.timestamp.to_i)
					v.update_descriptives(raw_tweet_text)
				end
			end

			tweet = Tweet.where("venue_id = ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", v.id).order("timestamp DESC").first
			if tweet != nil
				#v.set_last_tweet_details(tweet)
				latest_tweet_vc = VenueComment.where("tweet ->> 'id' = '#{tweet.id}'").first
				v.update_featured_comment(latest_tweet_vc)
				v.update_columns(last_tweet_id: latest_tweet_vc.tweet["twitter_id"])
			end
		else
		  raw_tweets.each{|raw_tweet| Tweet.create!(:twitter_id => raw_tweet.id, :tweet_text => raw_tweet.text, :image_url_1 => Tweet.implicit_image_url_1(raw_tweet), :image_url_2 => Tweet.implicit_image_url_2(raw_tweet), :image_url_3 => Tweet.implicit_image_url_3(raw_tweet), :author_id => raw_tweet.user.id, :handle => raw_tweet.user.screen_name, :author_name => raw_tweet.user.name, :author_avatar => raw_tweet.user.profile_image_url.to_s, :timestamp => raw_tweet.created_at, :from_cluster => true, :associated_zoomlevel => zoom_level, :latitude => cluster_lat, :longitude => cluster_long, :popularity_score => Tweet.popularity_score_calculation(raw_tweet.user.followers_count, raw_tweet.retweet_count, raw_tweet.favorite_count))}                                    
		end
	end

	def Tweet.convert_raw_tweet_params(raw_tweet_params, v_id)
		presence = Tweet.find_by_twitter_id(raw_tweet_params["tweet_id"])
		if Tweet.find_by_twitter_id(raw_tweet_params["tweet_id"]) == nil
			venue = Venue.find_by_id(v_id)
			new_tweet = Tweet.create!(:twitter_id => raw_tweet_params["tweet_id"], :tweet_text => raw_tweet_params["comment"], :image_url_1 => raw_tweet_params["tweet_image_url_1"], 
				:image_url_2 => raw_tweet_params["tweet_image_url_2"], :image_url_3 => raw_tweet_params["tweet_image_url_3"], :author_id => raw_tweet_params["twitter_user_id"], 
				:handle => raw_tweet_params["twitter_handle"], :author_name => raw_tweet_params["twitter_user_name"], :author_avatar => raw_tweet_params["twitter_user_avatar_url"], 
				:timestamp => raw_tweet_params["tweet_created_at"], :venue_id => venue.id, :popularity_score => 0)
			VenueComment.create!(:entry_type => "tweet", :venue_id => venue.id, :venue_details => venue.partial, :tweet => new_tweet.partial, :adjusted_sort_position => new_tweet.timestamp.to_i)
		else
			VenueComment.where("tweet ->> 'id' = '#{presence.id}'").first
		end
	end

	def Tweet.extract_meta_data(raw_tweet, v)
		hashtags =
		text = 
		clean_text =
		v.update_descriptives(clean_text)
		v.update_descriptives(clean_text)
	end

	def self.implicit_id(t)
		if t.try(:handle) != nil
			t.id
		else
			nil
		end
	end

	def self.implicit_twitter_id(t)
		if t.try(:handle) != nil
			t.twitter_id
		else
			t.id
		end  		
	end

	def self.implicit_text(t)
		if t.try(:handle) != nil
			t.tweet_text
		else
			t.text
		end  		
	end

	def self.implicit_image_url_1(t)
		if t.try(:handle) != nil
		  t.image_url_1
		else
		  media_url_string = t.try(:media).try(:first).try(:media_url).to_s
		  if media_url_string != ""
		    media_url_string+":small"
		  else
		    nil
		  end
		end     
	end

	def self.implicit_image_url_2(t)
		if t.try(:handle) != nil
		  t.image_url_2
		else
		  media_url_string = t.try(:media).try(:first).try(:media_url).to_s
		  if media_url_string != ""
		    media_url_string+":medium"
		  else
		    nil
		  end
		end     
	end

	def self.implicit_image_url_3(t)
		if t.try(:handle) != nil
		  t.image_url_3
		else
		  media_url_string = t.try(:media).try(:first).try(:media_url).to_s
		  if media_url_string != ""
		    media_url_string+":large"
		  else
		    nil
		  end
		end     
	end    

	def self.implicit_timestamp(t)
		if t.try(:handle) != nil
			t.timestamp
		else
			t.created_at
		end  		
	end

	def self.implicit_author_id(t)
		if t.try(:handle) != nil
			t.author_id
		else
			t.user.id
		end  		
	end

	def self.implicit_author_name(t)
		if t.try(:handle) != nil
			t.author_name
		else
			t.user.name
		end  		
	end

	def self.implicit_author_avatar(t)
		if t.try(:handle) != nil
			t.author_avatar
		else
			t.user.profile_image_url.to_s
		end
	end  

	def self.implicit_handle(t)
		if t.try(:handle) != nil
			t.handle
		else
			t.user.screen_name
		end  		
	end

	def Tweet.implicit_image_content_for_hash(tweet_hash, size)
		media_url = tweet_hash[:media].try([:first]).try([:media_url])
		if media_url != nil
		  media_url+":#{size}"
		else
		  nil
		end	
	end

	def Tweet.append_size_to_tweet_media_url(tweet_media_url, size)
		if tweet_media_url != nil
		  tweet_media_url+":"+size
		else
		  nil
		end
	end

  def Tweet.sort(i, j)
    if j == nil
      return 1
    else
      if i.created_at < Time.now-1.day && j.created_at < Time.now-1.day
        i.delete
        j.delete
        return 1
      elsif i.created_at < Time.now-1.day
        i.delete
        return 1
      elsif j.created_at < Time.now-1.day
        j.delete
        return 1
      else
        if Tweet.popularity_score_calculation(i.user.followers_count, i.retweet_count, i.favorite_count) > Tweet.popularity_score_calculation(j.user.followers_count, j.retweet_count, j.favorite_count)
          return -1
        elsif Tweet.popularity_score_calculation(i.user.followers_count, i.retweet_count, i.favorite_count) < Tweet.popularity_score_calculation(j.user.followers_count, j.retweet_count, j.favorite_count)
          return 1
        else
          return 0
        end      
      end
    end
  end	

end