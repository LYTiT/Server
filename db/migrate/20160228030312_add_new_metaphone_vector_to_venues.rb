class AddNewMetaphoneVectorToVenues < ActiveRecord::Migration
  def up
    add_column :venues, :metaphone_name_vector, :tsvector
    add_index :venues, :metaphone_name_vector, using: "gin"

    execute <<-EOS
      CREATE OR REPLACE FUNCTION fill_metaphone_name_vector_for_venue() RETURNS trigger LANGUAGE plpgsql AS $$
        
      begin

        new.metaphone_name_vector :=
          to_tsvector('pg_catalog.english', pg_search_dmetaphone(coalesce(new.name, '')));



        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER venues_metaphone_trigger BEFORE INSERT OR UPDATE
        ON venues FOR EACH ROW EXECUTE PROCEDURE fill_metaphone_name_vector_for_venue();
    EOS

    #Venue.find_each(&:touch)
  end

  def down
  	remove_index :venues, :metaphone_name_vector
    remove_column :venues, :metaphone_name_vector
    execute <<-EOS
      DROP TRIGGER venues_metaphone_trigger ON venues;
      DROP FUNCTION fill_metaphone_name_vector_for_venue();      
    EOS
  end
end
