class LytitBar < ActiveRecord::Base
  acts_as_singleton

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
