class AddNewSearchVectorsToVenues < ActiveRecord::Migration
  def up
  	add_column :venues, :ts_name_vector_expd, :tsvector
    add_index :venues, :ts_name_vector_expd, using: "gin"
    add_column :venues, :metaphone_name_vector_expd, :tsvector
    add_index :venues, :metaphone_name_vector_expd, using: "gin"

    execute <<-EOS
      CREATE OR REPLACE FUNCTION fill_ts_name_vector_expd_for_venue() RETURNS trigger LANGUAGE plpgsql AS $$
      declare
        venue_meta_data record;
        

      begin
        
        
        new.ts_name_vector_expd :=
        	setweight(to_tsvector('pg_catalog.english', coalesce(regexp_replace(new.name, '[^a-zA-Z\d\s:]+', '', 'g'), '')), 'A') ||
        	setweight(to_tsvector('pg_catalog.english', coalesce(regexp_replace(new.name, '[^a-zA-Z\d\s:]+', '', 'g')||new.city, '')), 'A');

        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER venues_ts_name_vector_expd_trigger BEFORE INSERT OR UPDATE
        ON venues FOR EACH ROW EXECUTE PROCEDURE fill_ts_name_vector_expd_for_venue();
    EOS

    execute <<-EOS
      CREATE OR REPLACE FUNCTION fill_metaphone_name_vector_expd_for_venue() RETURNS trigger LANGUAGE plpgsql AS $$
        
      begin

        new.metaphone_name_vector_expd :=
          setweight(to_tsvector('pg_catalog.english', pg_search_dmetaphone(coalesce(regexp_replace(new.name, '[^a-zA-Z\d\s:]+', '', 'g'), ''))), 'A') ||
          setweight(to_tsvector('pg_catalog.english', pg_search_dmetaphone(coalesce(regexp_replace(new.name, '[^a-zA-Z\d\s:]+', '', 'g')||new.city, ''))), 'A');



        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER venues_metaphone_expd_trigger BEFORE INSERT OR UPDATE
        ON venues FOR EACH ROW EXECUTE PROCEDURE fill_metaphone_name_vector_expd_for_venue();
    EOS

    #Venue.find_each(&:touch)    
  end

  def down
  	remove_index :venues, :ts_name_vector_expd
    remove_column :venues, :ts_name_vector_expd
    remove_index :venues, :metaphone_name_vector_expd
    remove_column :venues, :metaphone_name_vector_expd

    execute <<-EOS
      DROP TRIGGER venues_ts_name_vector_expd_trigger ON venues;
      DROP FUNCTION fill_ts_name_vector_expd_for_venue();      
    EOS

    execute <<-EOS
      DROP TRIGGER venues_metaphone_expd_trigger ON venues;
      DROP FUNCTION fill_metaphone_name_vector_expd_for_venue();      
    EOS
  end
end
