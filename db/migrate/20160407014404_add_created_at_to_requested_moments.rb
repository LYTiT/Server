class AddCreatedAtToRequestedMoments < ActiveRecord::Migration
  def change
  	  add_column(:moment_requests, :created_at, :datetime)
      add_column(:moment_requests, :updated_at, :datetime)
  end
end
