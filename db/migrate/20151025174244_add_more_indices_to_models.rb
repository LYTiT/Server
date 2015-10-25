class AddMoreIndicesToModels < ActiveRecord::Migration
  def change
  	add_index "tweets", ["popularity_score"]
  	add_index "tweets", ["timestamp"]
  	add_index "meta_data", ["relevance_score"]
  end
end
