class DropOutdatedTables2 < ActiveRecord::Migration
  def change
  	drop_table :live_users
  	drop_table :lumen_constants
  	drop_table :lumen_values
  	drop_table :temp_posting_housings
  	drop_table :venue_questions
  end
end
