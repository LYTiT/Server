class LumenConstants < ActiveRecord::Base
	#Media type weights
	TEXT_MEDIA_WEIGHT = 1
	IMAGE_MEDIA_WEIGHT = 5
	VIDEO_MEDIA_WEIGHT = 10

	POSTING_PAUSE = 5 #number of minutes that need to pass before content adds lumens
	
	VIEWS_WEIGHT_ADJ = 0.2 #scaling factor for adjusted comment views
	VIEWS_HALFLIFE = 44640.0 #(31*60*24) #halflife of a view in minutes

	VOTES_WEIGHT_ADJ = 0.1 #scaling factor for placed LYTiT votes

	def self.text_media_weight
		LumenConstants.where(:constant_name => 'text_media_weight').first.try(:constant_value) || TEXT_MEDIA_WEIGHT
	end

	def self.image_media_weight
		LumenConstants.where(:constant_name => 'image_media_weight').first.try(:constant_value) || IMAGE_MEDIA_WEIGHT
	end	

	def self.video_media_weight
		LumenConstants.where(:constant_name => 'video_media_weight').first.try(:constant_value) || VIDEO_MEDIA_WEIGHT
	end

	def self.posting_pause
		LumenConstants.where(:constant_name => 'posting_pause').first.try(:constant_value) || POSTING_PAUSE
	end

	def self.views_weight_adj
		LumenConstants.where(:constant_name => 'views_weight_adj').first.try(:constant_value) || VIEWS_WEIGHT_ADJ
	end

	def self.views_halflife
		LumenConstants.where(:constant_name => 'views_halflife').first.try(:constant_value) || VIEWS_HALFLIFE
	end

	def self.votes_weight_adj
		LumenConstants.where(:constant_name => 'votes_weight_adj').first.try(:constant_value) || VOTES_WEIGHT_ADJ
	end 
	
end
