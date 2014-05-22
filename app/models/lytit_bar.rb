class LytitBar
  include Singleton

  # refer LYTiT algorithm documentation
  GOOGLE_PLACE_FACTOR = 20

  BAYESIAN_AVERAGE_C = 0.1 # C constant
  BAYESIAN_AVERAGE_M = 2 # m constant

  attr_accessor :position

  def initialize
    @position = 0
  end

  def recalculate_bar_position
    sum = 0
    venues = Venue.all
    venues.each do |venue|
      sum += venue.bayesian_voting_average
    end

    if not venues.empty?
      @position = sum / venues.size
	else
      @position = 0
    end
  end
end
