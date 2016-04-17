namespace :lytit do

  desc "called by Heroku scheduler in order to generate new CSV reports every day at 6am"
  task :generate_reports => :environment do
    puts "Generating CSVs..."

    #VotesCsv.instance.write_csv
    #VenuesCsv.instance.write_csv
    
    puts "done."
  end

end