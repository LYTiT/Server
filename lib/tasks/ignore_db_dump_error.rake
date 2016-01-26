namespace :lytit do
	if Rails.env == 'production'
    	Rake::Task["db:structure:dump"].clear
	end
end