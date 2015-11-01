class AddVenueToGroups < ActiveRecord::Migration
  def change
    add_reference :groups, :venue, index: true
  end
end
