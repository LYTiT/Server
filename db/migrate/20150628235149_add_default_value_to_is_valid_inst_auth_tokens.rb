class AddDefaultValueToIsValidInstAuthTokens < ActiveRecord::Migration
	def up
		change_column :instagram_auth_tokens, :is_valid, :boolean, :default => true
	end

	def down
		change_column :instagram_auth_tokens, :is_valid, :boolean, :default => nil
	end
end
