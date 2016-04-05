class AddCoordinatesToMomentRequests < ActiveRecord::Migration
  def change
  	add_column :moment_requests, :latitude, :float, :index => true
  	add_column :moment_requests, :longitude, :float, :index => true
  	add_column :moment_requests, :num_requesters, :integer, :default => 0
  	add_column :moment_requests, :expiration, :datetime
  end
end
