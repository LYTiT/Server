class CreateVendorIdTrackers < ActiveRecord::Migration
  def change
    create_table :vendor_id_trackers do |t|
   		t.string :used_vendor_id, index: true
    end
  end
end
