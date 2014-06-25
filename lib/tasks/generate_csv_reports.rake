namespace :lytit do

  desc "called by Heroku scheduler in order to generate new CSV reports every day at 6am"
  task :generate_reports => :environment do
    puts "Generating CSVs..."

    CsvGenerator.by_vote
    CsvGenerator.by_venue
    
    puts "done."
  end

end