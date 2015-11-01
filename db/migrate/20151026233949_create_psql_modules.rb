class CreatePsqlModules < ActiveRecord::Migration
	def up
	  execute "create extension fuzzystrmatch"
	  execute "create extension pg_trgm"
	end

	def down
		execute "disable extension fuzzystrmatch"
		execute "disable extension pg_trgm"
	end
end
