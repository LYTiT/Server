class DropMetaphoneVectorOnVenues < ActiveRecord::Migration
  def change
  	remove_index :venues, :metaphone_name_vector
    remove_column :venues, :metaphone_name_vector
    execute <<-EOS
      DROP TRIGGER venues_metaphone_trigger ON venues;
      DROP FUNCTION fill_metaphone_name_vector_for_venue();      
    EOS
  end
end
