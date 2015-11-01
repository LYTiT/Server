class CreateFunctionAndTriggerForFillingSearchVectorOfVenues < ActiveRecord::Migration
  def up
    execute <<-EOS
      CREATE OR REPLACE FUNCTION fill_meta_data_vector_for_venue() RETURNS trigger LANGUAGE plpgsql AS $$
      declare
        venue_meta_data record;
        

      begin
        
        
        select string_agg(meta, ' ') as meta into venue_meta_data from meta_data where venue_id = new.id and (NOW() - created_at) <= INTERVAL '1 DAY';

        new.meta_data_vector :=
          to_tsvector('pg_catalog.english', coalesce(venue_meta_data.meta, ''));


        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER venues_meta_data_trigger BEFORE INSERT OR UPDATE
        ON venues FOR EACH ROW EXECUTE PROCEDURE fill_meta_data_vector_for_venue();
    EOS

    Venue.find_each(&:touch)
  end

  def down
    execute <<-EOS
      DROP TRIGGER venues_meta_data_trigger ON venues;
      DROP FUNCTION fill_meta_data_vector_for_venue();      
    EOS
  end
end