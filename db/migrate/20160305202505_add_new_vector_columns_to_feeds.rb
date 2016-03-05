class AddNewVectorColumnsToFeeds < ActiveRecord::Migration
  def up
    add_column :feeds, :ts_name_vector, :tsvector
    add_index :feeds, :ts_name_vector, using: "gin"

    add_column :feeds, :ts_description_vector, :tsvector
    add_index :feeds, :ts_description_vector, using: "gin"

    add_column :feeds, :ts_categories_vector, :tsvector
    add_index :feeds, :ts_categories_vector, using: "gin"

    add_column :feeds, :ts_meta_vector, :tsvector
    add_index :feeds, :ts_meta_vector, using: "gin"


    execute <<-EOS
      CREATE OR REPLACE FUNCTION fill_ts_name_vector_for_feed() RETURNS trigger LANGUAGE plpgsql AS $$

      begin 
        new.ts_name_vector :=
        	to_tsvector('pg_catalog.english', coalesce(new.name, ''));

        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER feeds_ts_name_vector_trigger BEFORE INSERT OR UPDATE
        ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_ts_name_vector_for_feed();
    EOS


    execute <<-EOS
    	CREATE OR REPLACE FUNCTION fill_ts_description_vector_for_feed() RETURNS trigger LANGUAGE plpgsql AS $$

	 	begin         
        new.ts_description_vector :=
        	to_tsvector('pg_catalog.english', coalesce(new.description, ''));

        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER feeds_ts_description_vector_trigger BEFORE INSERT OR UPDATE
        ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_ts_description_vector_for_feed();
    EOS


    execute <<-EOS
      CREATE OR REPLACE FUNCTION fill_ts_categories_vector_for_feed() RETURNS trigger LANGUAGE plpgsql AS $$
      declare
      	assgined_category record;
        
      begin

      	select string_agg(category, ' ') as category into assgined_category from feed_recommendations where feed_id = new.id and category is not null;

        new.ts_categories_vector :=
          to_tsvector('pg_catalog.english', coalesce(assgined_category.category, ''));


        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER feeds_ts_categories_vector_trigger BEFORE INSERT OR UPDATE
        ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_ts_categories_vector_for_feed();
    EOS


    execute <<-EOS
      CREATE OR REPLACE FUNCTION fill_ts_meta_vector_for_feed() RETURNS trigger LANGUAGE plpgsql AS $$
      declare
      	feed_venue_data record;
      	assgined_category record;
        
      begin

      	select string_agg(description, ' ') as added_note into feed_venue_data from feed_venues where feed_id = new.id;

        new.ts_meta_vector :=
          to_tsvector('pg_catalog.english', coalesce(feed_venue_data.added_note, ''));


        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER feeds_ts_meta_vector_trigger BEFORE INSERT OR UPDATE
        ON feeds FOR EACH ROW EXECUTE PROCEDURE fill_ts_meta_vector_for_feed();
    EOS

    Feed.find_each(&:touch)
  end

  def down
  	remove_index :feeds, :ts_name_vector
    remove_column :feeds, :ts_name_vector

    remove_index :feeds, :ts_description_vector
    remove_column :feeds, :ts_description_vector

    remove_index :feeds, :ts_categories_vector
    remove_column :feeds, :ts_categories_vector

    remove_index :feeds, :ts_meta_vector
    remove_column :feeds, :ts_meta_vector    


    execute <<-EOS
      DROP TRIGGER feeds_ts_name_vector_trigger ON feeds;
      DROP FUNCTION fill_ts_name_vector_for_feed();      
    EOS

    execute <<-EOS
      DROP TRIGGER feeds_ts_description_vector_trigger ON feeds;
      DROP FUNCTION fill_ts_description_vector_for_feed();      
    EOS

    execute <<-EOS
      DROP TRIGGER feeds_ts_categories_vector_trigger ON feeds;
      DROP FUNCTION fill_ts_categories_vector_for_feed();      
    EOS

    execute <<-EOS
      DROP TRIGGER feeds_ts_meta_vector_trigger ON feeds;
      DROP FUNCTION fill_ts_meta_vector_for_feed();      
    EOS

  end
end

