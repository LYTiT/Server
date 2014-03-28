class SystemController < ApplicationController
  def status
    render :json => {:message => 'System is up!!'}
  end
end
