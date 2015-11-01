class LytitConstants < ActiveRecord::Base

  # refer LYTiT algorithm documentation
  GOOGLE_PLACE_FACTOR_DEF = 20

  BAYESIAN_AVERAGE_C_DEF = 0.1 # C constant
  BAYESIAN_AVERAGE_M_DEF = 2.0 # m constant

  VOTE_HALF_LIFE_H_DEF = 30
  RATING_LOSS_L_DEF = 10

  THRESHOLD_TO_BE_SHOWN_ON_MAP_DEF = 210 # 3.5 hours
  #-------------------------------------

  def self.google_place_factor
  	LytitConstants.where(:constant_name => 'google_place_factor').first.try(:constant_value) || GOOGLE_PLACE_FACTOR_DEF
  end

  def self.bayesian_average_c
  	LytitConstants.where(:constant_name => 'bayesian_average_c').first.try(:constant_value) || BAYESIAN_AVERAGE_C_DEF
  end

  def self.bayesian_average_m
  	LytitConstants.where(:constant_name => 'bayesian_average_m').first.try(:constant_value) || BAYESIAN_AVERAGE_M_DEF
  end

  def self.vote_half_life_h
  	LytitConstants.where(:constant_name => 'vote_half_life_h').first.try(:constant_value) || VOTE_HALF_LIFE_H_DEF
  end

  def self.rating_loss_l
  	LytitConstants.where(:constant_name => 'rating_loss_l').first.try(:constant_value) || RATING_LOSS_L_DEF
  end

  def self.threshold_to_venue_be_shown_on_map
  	LytitConstants.where(:constant_name => 'threshold_to_venue_be_shown_on_map').first.try(:constant_value) || THRESHOLD_TO_BE_SHOWN_ON_MAP_DEF
  end
end
