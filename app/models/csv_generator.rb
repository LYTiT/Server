class CsvGenerator

  def self.by_vote
    votes = LytitVote.where('created_at >= ?', Time.now.at_beginning_of_day + 6.hours)

    by_vote = CSV.open("csv_test.csv", "wb") do |csv|
      data = ["ID", "Vote Type (up or down)", "Venue at which vote was placed", "Time at which vote was placed", 
      	      "LYTiT Rating at Venue at time of placed vote", "Priming Value of Venue where vote was placed"]

      csv << data

      votes.each do |v|
      	data = [v.id, v.value > 0 ? "up" : "down", v.venue_id, v.created_at, v.venue_rating, v.prime]

      	csv << data
      end
    end
  end

end