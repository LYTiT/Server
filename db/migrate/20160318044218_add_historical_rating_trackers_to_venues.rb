class AddHistoricalRatingTrackersToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :hist_rating_avgs, :json, default: {:hour_1=>{:rating=> 0, :count => 0}, 
  	:hour_2=>{:rating=> 0, :count => 0}, :hour_3=>{:rating=> 0, :count => 0}, :hour_4=>{:rating=> 0, :count => 0},
  	:hour_5=>{:rating=> 0, :count => 0}, :hour_6=>{:rating=> 0, :count => 0},
  	:hour_7=>{:rating=> 0, :count => 0}, :hour_8=>{:rating=> 0, :count => 0}, :hour_9=>{:rating=> 0, :count => 0},
  	:hour_10=>{:rating=> 0, :count => 0}, :hour_11=>{:rating=> 0, :count => 0}, :hour_12=>{:rating=> 0, :count => 0},
  	:hour_13=>{:rating=> 0, :count => 0}, :hour_14=>{:rating=> 0, :count => 0}, :hour_15=>{:rating=> 0, :count => 0},
  	:hour_16=>{:rating=> 0, :count => 0}, :hour_17=>{:rating=> 0, :count => 0}, :hour_18=>{:rating=> 0, :count => 0},
  	:hour_19=>{:rating=> 0, :count => 0}, :hour_20=>{:rating=> 0, :count => 0}, :hour_21=>{:rating=> 0, :count => 0},
  	:hour_22=>{:rating=> 0, :count => 0}, :hour_23=>{:rating=> 0, :count => 0}, :hour_0=>{:rating=> 0, :count => 0},}, null: false
  end
end
