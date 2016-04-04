class AddDescriptiveColumnsToUsersVenuesLists < ActiveRecord::Migration
  def up
  	add_column :users, :interests, :json, default: {}, null: false
  	add_column :venues, :categories, :json, default: {}, null: false
  	add_column :venues, :categories_string, :text, default: ''
  	add_column :venues, :trending_tags, :json, default: {}, null: false
  	add_column :venues, :trending_tags_string, :text, default: ''
  	add_column :venues, :descriptives, :json, default: {}, null: false
  	add_column :venues, :descriptives_string, :text, default: ''

  	add_column :venues, :descriptives_vector, :tsvector
    add_index :venues, :descriptives_vector, using: "gin"


    execute <<-EOS
      CREATE OR REPLACE FUNCTION fill_descriptives_vector_for_venue() RETURNS trigger LANGUAGE plpgsql AS $$

      begin               
        new.descriptives_vector :=
          setweight(to_tsvector('pg_catalog.english', coalesce(new.categories_string, '')), 'A') ||
          setweight(to_tsvector('pg_catalog.english', coalesce(new.descriptives_string, '')), 'B')||
          setweight(to_tsvector('pg_catalog.english', coalesce(new.trending_tags_string, '')), 'B');

        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER venues_descriptives_vector_trigger BEFORE INSERT OR UPDATE
        ON venues FOR EACH ROW EXECUTE PROCEDURE fill_descriptives_vector_for_venue();
    EOS
  end

  def down
  	remove_index :venues, :descriptives_vector
  	remove_column :users, :interests
  	remove_column :venues, :trending_tags
  	remove_column :venues, :trending_tags_string
  	remove_column :venues, :categories
  	remove_column :venues, :categories_string
  	remove_column :venues, :descriptives
  	remove_column :venues, :descriptives_string
  	remove_column :venues, :descriptives_vector

        

    execute <<-EOS
      DROP TRIGGER venues_descriptives_vector_trigger ON venues;
      DROP FUNCTION fill_descriptives_vector_for_venue();      
    EOS

  end
end
