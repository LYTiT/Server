class AddInSpotlytToList < ActiveRecord::Migration
  def change
  	add_column :feeds, :in_spotlyt, :boolean, default: true
  end
end
