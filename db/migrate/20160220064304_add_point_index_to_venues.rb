class AddPointIndexToVenues < ActiveRecord::Migration
  def up
    execute %{
      create index index_on_venues_location ON venues using gist (
        ST_GeographyFromText(
          'SRID=4326;POINT(' || venues.longitude || ' ' || venues.latitude || ')'
        )
      )
    }
  end

  def down
    execute %{drop index index_on_venues_location}
  end
end
