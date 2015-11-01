class AddUserRefToVenues < ActiveRecord::Migration
  def change
    add_reference :venues, :user, index: true
  end
end
