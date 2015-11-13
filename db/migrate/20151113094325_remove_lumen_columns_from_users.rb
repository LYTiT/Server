class RemoveLumenColumnsFromUsers < ActiveRecord::Migration
  def change
  	remove_column :users, :lumens, :double
  	remove_column :users, :lumen_percentile, :double
  	remove_column :users, :video_lumens, :double
  	remove_column :users, :image_lumens, :double
  	remove_column :users, :text_lumens, :double
  	remove_column :users, :bonus_lumens, :double
  	remove_column :users, :total_views, :integer
  	remove_column :users, :lumen_notification, :double
  	remove_column :users, :latest_rejection_time, :datetime
  	remove_column :users, :adjusted_view_discount, :double
  	remove_column :users, :monthly_gross_lumens, :double
  end
end
