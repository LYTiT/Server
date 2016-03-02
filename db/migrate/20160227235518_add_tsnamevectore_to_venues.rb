class AddTsnamevectoreToVenues < ActiveRecord::Migration
  def up
  	add_column :venues, :ts_name_vector, :tsvector
    add_index :venues, :ts_name_vector, using: "gin"

    execute <<-EOS
      CREATE OR REPLACE FUNCTION fill_ts_name_vector_for_venue() RETURNS trigger LANGUAGE plpgsql AS $$
      declare
        venue_meta_data record;
        

      begin
        
        
        new.ts_name_vector :=
        	to_tsvector('pg_catalog.english', coalesce(new.name||new.city, ''));

        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER venues_ts_name_vector_trigger BEFORE INSERT OR UPDATE
        ON venues FOR EACH ROW EXECUTE PROCEDURE fill_ts_name_vector_for_venue();
    EOS

    #Venue.find_each(&:touch)    
  end

  def down
  	remove_index :venues, :ts_name_vector
    remove_column :venues, :ts_name_vector
    execute <<-EOS
      DROP TRIGGER venues_ts_name_vector_trigger ON venues;
      DROP FUNCTION fill_ts_name_vector_for_venue();      
    EOS
  end
end
