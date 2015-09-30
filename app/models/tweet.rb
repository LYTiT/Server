class Tweet < ActiveRecord::Base
	acts_as_mappable :default_units => :miles,
	             :default_formula => :sphere,
	             :distance_field_name => :distance,
	             :lat_column_name => :latitude,
	             :lng_column_name => :longitude

	belongs_to :venue

	def self.popularity_score_calculation(followers_count, retweet_count, favorite_count)
		#we calculate the 'importance' of a tweet through a combination of retweet count as well as tweet user follower count considerations: [1/(e^(-alpha_factor * follower_count ^(beta_factor)) + 1) + retweet_count^(1/gamma_factor)]
		alpha_factor = 0.1
		beta_factor = 0.27
		gamma_factor = 5.0

		tweet_popularity_score = 1.0 / (Math::E ** (-alpha_factor.to_f * followers_count.to_f ** beta_factor) + 1.0) + retweet_count.to_f ** (1.0 / gamma_factor)      
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
        t.try(:media).try(:first).try(:media_url).to_s+":small"
      end     
    end

    def self.implicit_image_url_2(t)
      if t.try(:handle) != nil
        t.image_url_2
      else
        t.try(:media).try(:first).try(:media_url).to_s+":medium"
      end     
    end

    def self.implicit_image_url_3(t)
      if t.try(:handle) != nil
        t.image_url_3
      else
        t.try(:media).try(:first).try(:media_url).to_s+":large"
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

end