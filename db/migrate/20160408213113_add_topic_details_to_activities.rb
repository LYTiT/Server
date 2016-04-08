class AddTopicDetailsToActivities < ActiveRecord::Migration
  def change
  	  	add_column :activities, :topic_details, :json, default: {}, null: false
  end
end
