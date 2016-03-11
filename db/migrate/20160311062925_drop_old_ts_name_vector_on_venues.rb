class DropOldTsNameVectorOnVenues < ActiveRecord::Migration
  def change
  	remove_index :venues, :ts_name_vector
    remove_column :venues, :ts_name_vector
    execute <<-EOS
      DROP TRIGGER venues_ts_name_vector_trigger ON venues;
      DROP FUNCTION fill_ts_name_vector_for_venue();           
    EOS
  end
end
