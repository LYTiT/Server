require 'rufus-scheduler'

# Let's use the rufus-scheduler singleton
#
s = Rufus::Scheduler.singleton

# Recalculate LytitBar position every 5 minutes
#
s.every '5m' do
  LytitBar.instance.recalculate_bar_position
  puts 'Bar updated.'
end

# Recalculate venues ratings every 5 minutes
s.every '5m' do
	puts 'Recalculating ratings'
	Venue.all.each do |venue|
		venue.recalculate_rating
	end
	puts 'Ratings refreshed.'
end