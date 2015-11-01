class AddDefaultValueToTweets < ActiveRecord::Migration
  	def up
		change_column :tweets, :popularity_score, :float, :default => 0.0
	end

	def down
		change_column :tweets, :popularity_score, :float, :default => nil
	end
end
