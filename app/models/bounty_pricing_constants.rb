class BountyPricingConstants < ActiveRecord::Base
	#Media type weights
	TEXT_MEDIA_WEIGHT = 1.0
	IMAGE_MEDIA_WEIGHT = 5.0
	VIDEO_MEDIA_WEIGHT = 10.0

	#We price a bounty linearly as follows (media_type weight)*(slope*bounty_lifespan+intercept) = lumen_price
	SLOPE = (-3.0/115.0)
	INTERCEPT = 95.0/23.0

	def self.text_media_weight
		BountyPricingConstants.where(:constant_name => 'text_media_weight').first.try(:constant_value) || TEXT_MEDIA_WEIGHT
	end

	def self.image_media_weight
		BountyPricingConstants.where(:constant_name => 'image_media_weight').first.try(:constant_value) || IMAGE_MEDIA_WEIGHT
	end	

	def self.video_media_weight
		BountyPricingConstants.where(:constant_name => 'video_media_weight').first.try(:constant_value) || VIDEO_MEDIA_WEIGHT
	end

	def self.slope
		BountyPricingConstants.where(:constant_name => 'slope').first.try(:constant_value) || SLOPE
	end

	def self.intercept
		BountyPricingConstants.where(:constant_name => 'intercept').first.try(:constant_value) || INTERCEPT
	end
	
end