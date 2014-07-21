class Api::V1::AccesscodesController < ApplicationController
  
  def new 

  end

  def show

  	#@accesscode = Accesscode.new(accesscodes_params)
  	accesscode = Accesscode.where(code: params[:id]).take
  	accesscode.kvalue = accesscode.kvalue + 1
  	accesscode.save
 	render json: {code: accesscode }
  end

  def update

  end

  def create
  	@accesscode = Accesscode.new(accesscodes_params)
  end

  def val_accesscode

  	@accesscode = Accesscode.find_by_code(params[:code])
  end
  
  private 

  def accesscodes_params
  	params.require(:accesscode).permit(:code, :kvalue)
  end
end
