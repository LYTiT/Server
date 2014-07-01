class LytitBar < ActiveRecord::Base
  acts_as_singleton

  # refer LYTiT algorithm documentation
  GOOGLE_PLACE_FACTOR = 20

  BAYESIAN_AVERAGE_C = 0.1 # C constant
  BAYESIAN_AVERAGE_M = 2.0 # m constant

  VOTE_HALF_LIFE_H = 30
  RATING_LOSS_L = 10

  THRESHOLD_TO_BE_SHOWN_ON_MAP = 210 # 3.5 hours
  #-------------------------------------

  def recalculate_bar_position
    sum = 0
    venues = Venue.all
    venues.each do |venue|
      sum += venue.bayesian_voting_average
    end

    if not venues.empty?
      self.position = sum / venues.size
	  else
      self.position = 0
    end

    save
  end

  def self.inv_inc_beta(a, b, y)
    RubyPython.start(:python_exe => '/usr/local/bin/python2.7')
    scipy = RubyPython.import('scipy.special')
    scipy.betaincinv(a, b, y)
  end
end
