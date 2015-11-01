class AddMediaTypeToLumenValues < ActiveRecord::Migration
  def change
  	add_column :lumen_values, :media_type, :string
  end
end
