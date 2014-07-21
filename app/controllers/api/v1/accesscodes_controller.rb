class Api::V1::AccesscodesController < ApplicationController
  
  def new 

  end

  def val_accesscode
  	@accesscode = Accesscode.find_by_code(params[:code])

  end
  
  def update

  end

  def create
  	@accesscode = Accesscode.new(accesscodes_params)
  end

  private 

  def accesscodes_params
  		params.require(:accesscode).permit(:code, :kvalue)
  end
end
