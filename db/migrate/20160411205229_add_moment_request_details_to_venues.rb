class AddMomentRequestDetailsToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :moment_request_details, :json, default: {}, null: false
  end
end
