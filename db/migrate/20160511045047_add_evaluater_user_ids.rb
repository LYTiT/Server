class AddEvaluaterUserIds < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :evaluater_user_ids, :json, default: {}, null: false
  	rename_column :venue_comments, :views, :num_enlytened
  end
end
