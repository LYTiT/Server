class AddVectorColumnToVenueComments < ActiveRecord::Migration
  def up
    add_column :venue_comments, :meta_data_vector, :tsvector
    add_index :venue_comments, :meta_data_vector, using: "gin"

    execute <<-EOS
      CREATE OR REPLACE FUNCTION fill_meta_data_vector_for_venue_comments() RETURNS trigger LANGUAGE plpgsql AS $$
      declare
        venue_comment_meta_data record;
        

      begin
        
        
        select string_agg(meta, ' ') as meta into venue_comment_meta_data from meta_data where venue_comment_id = new.id and (NOW() - created_at) <= INTERVAL '1 DAY';

        new.meta_data_vector :=
          to_tsvector('pg_catalog.english', coalesce(venue_comment_meta_data.meta, ''));


        return new;
      end
      $$;
    EOS

    execute <<-EOS
      CREATE TRIGGER venues_comment_meta_data_trigger BEFORE INSERT OR UPDATE
        ON venue_comments FOR EACH ROW EXECUTE PROCEDURE fill_meta_data_vector_for_venue_comments();
    EOS

    
  end

  def down
  	remove_index :venue_comments, :meta_data_vector
    remove_column :venue_comments, :meta_data_vector
    execute <<-EOS
      DROP TRIGGER venues_comment_meta_data_trigger ON venue_comments;
      DROP FUNCTION fill_meta_data_vector_for_venue_comments();
    EOS
  end
end
