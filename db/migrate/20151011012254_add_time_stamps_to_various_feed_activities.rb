class AddTimeStampsToVariousFeedActivities < ActiveRecord::Migration
  def change
  	  	add_column(:feed_topics, :created_at, :datetime)
		add_column(:feed_topics, :updated_at, :datetime)
		add_column(:feed_shares, :created_at, :datetime)
		add_column(:feed_shares, :updated_at, :datetime)
		add_column(:feed_recommendations, :created_at, :datetime)
		add_column(:feed_recommendations, :updated_at, :datetime)		
  end
end
