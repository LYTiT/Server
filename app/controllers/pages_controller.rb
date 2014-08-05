class PagesController < ApplicationController

  layout 'venue_manager'

  def home
    render layout: "application"
  end
  
end
