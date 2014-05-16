class VenuesController < ApplicationController

  def reported_comments
    @flagged_comments = FlaggedComment.order('id DESC')
  end

end
