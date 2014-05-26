class Api::V1::LytitBarController < ApplicationController

  def position
  	render json: { 'bar_position' => LytitBar.instance.position }
  end
  
end
