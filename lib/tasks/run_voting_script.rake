namespace :lytit do

  desc "called by Heroku scheduler in order to reset variables and LYTiT bar position every day at 6am"
  task :run_script => :environment do
    exec 'python voting_script.py dev 012b5c949996f20ce537b43fb88b5aad 60'
  end

  task :stop_script => :environment do
    exec 'killall python'
  end

end