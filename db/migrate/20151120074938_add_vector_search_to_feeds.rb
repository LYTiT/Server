class AddVectorSearchToFeeds < ActiveRecord::Migration
  def up
    add_column :feeds, :search_vector, :tsvector
    add_index :feeds, :search_vector, using: "gin"

    execute <<-EOS
      CREATE OR REPLACE FUNCTION fill_search_vector_for_feed() RETURNS trigger LANGUAGE plpgsql AS $$
      declare
      	feed_venue_data record;
        
      begin

      	select string_agg(description, ' ') as added_note into feed_venue_data from feed_venues where feed_id = new.id;

        new.search_vector :=
          setweight(to_tsvector('pg_catalog.english', coalesce(new.name, '')), 'A') ||
          setweight(to_tsvector('pg_catalog.english', coalesce(new.description, '')), 'B') ||
          setweight(to_tsvector('pg_catalog.english', coalesce(feed_venue_data.added_note, '')), 'C');

        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER feed_search_trigger BEFORE INSERT OR UPDATE
        ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_search_vector_for_feed();
    EOS

    Feed.find_each(&:touch)
  end

  def down
  	remove_index :feeds, :search_vector
    remove_column :feeds, :search_vector
    execute <<-EOS
      DROP TRIGGER feed_search_trigger ON venues;
      DROP FUNCTION fill_search_vector_for_feed();      
    EOS
  end
end
