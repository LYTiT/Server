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

	def self.popularity_score_calculation(followers_count, retweet_count, favorite_count)
	#we calculate the 'importance' of a tweet through a combination of retweet count as well as tweet user follower count considerations: [1/(e^(-alpha_factor * follower_count ^(beta_factor)) + 1) + retweet_count^(1/gamma_factor)]
	alpha_factor = 0.1
	beta_factor = 0.27
	gamma_factor = 5.0

	tweet_popularity_score = 1.0 / (Math::E ** (-alpha_factor.to_f * followers_count.to_f ** beta_factor) + 1.0) + retweet_count.to_f ** (1.0 / gamma_factor)      
	end


	def self.bulk_conversion(raw_tweets, v, cluster_lat, cluster_long, zoom_level, map_scale)
		if v != nil
			#raw_tweets.each{|raw_tweet| Tweet.create!(:twitter_id => raw_tweet.id, :tweet_text => raw_tweet.text, :image_url_1 => Tweet.implicit_image_url_1(raw_tweet), :image_url_2 => Tweet.implicit_image_url_2(raw_tweet), :image_url_3 => Tweet.implicit_image_url_3(raw_tweet), :author_id => raw_tweet.user.id, :handle => raw_tweet.user.screen_name, :author_name => raw_tweet.user.name, :author_avatar => raw_tweet.user.profile_image_url.to_s, :timestamp => raw_tweet.created_at, :from_cluster => false, :venue_id => v.id, :popularity_score => Tweet.popularity_score_calculation(raw_tweet.user.followers_count, raw_tweet.retweet_count, raw_tweet.favorite_count))}
			for raw_tweet in raw_tweets
				if Tweet.find_by_twitter_id(raw_tweet.id) == nil
					new_tweet = Tweet.create!(:twitter_id => raw_tweet.id, :tweet_text => raw_tweet.text, :image_url_1 => Tweet.implicit_image_url_1(raw_tweet), :image_url_2 => Tweet.implicit_image_url_2(raw_tweet), :image_url_3 => Tweet.implicit_image_url_3(raw_tweet), :author_id => raw_tweet.user.id, :handle => raw_tweet.user.screen_name, :author_name => raw_tweet.user.name, :author_avatar => raw_tweet.user.profile_image_url.to_s, :timestamp => raw_tweet.created_at, :from_cluster => false, :venue_id => v.id, :popularity_score => Tweet.popularity_score_calculation(raw_tweet.user.followers_count, raw_tweet.retweet_count, raw_tweet.favorite_count))
					VenueComment.create!(:entry_type => "tweet", :venue_id => v.id, :venue_details => v.partial, :tweet => new_tweet.partial, :adjusted_sort_position => new_tweet.timestamp.to_i)
				end
			end

			tweet = Tweet.where("venue_id = ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", v.id).order("timestamp DESC").order("popularity_score DESC").first
			if tweet != nil
				v.set_last_tweet_details(tweet)
			end
		else
		  raw_tweets.each{|raw_tweet| Tweet.create!(:twitter_id => raw_tweet.id, :tweet_text => raw_tweet.text, :image_url_1 => Tweet.implicit_image_url_1(raw_tweet), :image_url_2 => Tweet.implicit_image_url_2(raw_tweet), :image_url_3 => Tweet.implicit_image_url_3(raw_tweet), :author_id => raw_tweet.user.id, :handle => raw_tweet.user.screen_name, :author_name => raw_tweet.user.name, :author_avatar => raw_tweet.user.profile_image_url.to_s, :timestamp => raw_tweet.created_at, :from_cluster => true, :associated_zoomlevel => zoom_level, :latitude => cluster_lat, :longitude => cluster_long, :popularity_score => Tweet.popularity_score_calculation(raw_tweet.user.followers_count, raw_tweet.retweet_count, raw_tweet.favorite_count))}                                    
		end
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

end