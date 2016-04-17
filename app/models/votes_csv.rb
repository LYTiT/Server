=begin
class VotesCsv < ExportedDataCsv

  protected

  def filename
    'votes_report'
  end

  def data_string
    votes = LytitVote.where('created_at >= ?', valid_votes_timestamp)

    by_vote = CSV.generate do |csv|
      data = ["ID", "Vote Type (up or down)", "Venue at which vote was placed", "Time at which vote was placed", 
              "LYTiT Rating at Venue at time of placed vote (BEFORE)", "LYTiT Rating at Venue at time of placed vote (AFTER)",
              "Priming Value of Venue where vote was placed"]

      csv << data

      votes.each do |v|
        data = [v.id, v.value > 0 ? "up" : "down", v.venue_id, v.created_at, v.venue_rating, v.rating_after, v.prime]

      	csv << data
      end
    end
  end

  private

  def valid_votes_timestamp
    now = Time.now
    now.hour >= 6 ? now.at_beginning_of_day + 6.hours : now.yesterday.at_beginning_of_day + 6.hours
  end
end
=end