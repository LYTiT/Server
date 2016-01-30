class AddMediaTypeToActivities < ActiveRecord::Migration
  def change
  	add_column :activities, :media_type, :string
  end
end
