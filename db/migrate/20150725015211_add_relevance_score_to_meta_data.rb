class AddRelevanceScoreToMetaData < ActiveRecord::Migration
  def change
  	add_column :meta_data, :relevance_score, :float, :default => 0.0 
  end
end
