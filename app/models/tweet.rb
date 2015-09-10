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

end