class UpdateFeedVectoreColumns < ActiveRecord::Migration
	def up
		add_column :feeds, :ts_venue_descriptives_vector, :tsvector
		add_index :feeds, :ts_venue_descriptives_vector, using: "gin"

	    execute <<-EOS
	      CREATE OR REPLACE FUNCTION fill_ts_venue_descriptives_vector_for_feed() RETURNS trigger LANGUAGE plpgsql AS $$
	      declare
	      feed_venue_descriptives record;	      

	      begin 
	      	SELECT string_agg(description, ' ') AS descriptives INTO feed_venue_descriptives FROM feed_venues WHERE feed_id = new.id;

	        new.ts_venue_descriptives_vector :=
	        	to_tsvector('pg_catalog.english', coalesce(feed_venue_descriptives.descriptives, ''));

	        return new;
	      end
	      $$;
	    EOS

	    execute <<-EOS
	      CREATE TRIGGER feeds_ts_venue_descriptives_vector_trigger BEFORE INSERT OR UPDATE
	        ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_ts_venue_descriptives_vector_for_feed();
	    EOS



	    execute <<-EOS
	      CREATE OR REPLACE FUNCTION fill_ts_categories_vector_for_feed() RETURNS trigger LANGUAGE plpgsql AS $$
	      declare
	      feed_category_entries record;	      

	      begin 
	      	SELECT string_agg(name, ' ') AS names INTO feed_category_entries FROM list_categories WHERE id IN (SELECT list_category_id FROM list_category_entries WHERE feed_id = new.id);

	        new.ts_categories_vector :=
	        	to_tsvector('pg_catalog.english', coalesce(feed_category_entries.names, ''));

	        return new;
	      end
	      $$;
	    EOS

	    execute <<-EOS
	      CREATE TRIGGER feeds_ts_categories_vector_trigger BEFORE INSERT OR UPDATE
	        ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_ts_categories_vector_for_feed();
	    EOS

	    Feed.find_each(&:touch)

	end

	def down
		remove_index :feeds, :ts_venue_descriptives_vector
		remove_column :feeds, :ts_venue_descriptives_vector

		execute <<-EOS
			DROP TRIGGER feeds_ts_venue_descriptives_vector_trigger ON feeds;
 			DROP FUNCTION fill_ts_venue_descriptives_vector_for_feed();      
		EOS

		execute <<-EOS
			DROP TRIGGER feeds_ts_categories_vector_trigger ON feeds;
 			DROP FUNCTION fill_ts_categories_vector_for_feed();      
		EOS

	end
end
