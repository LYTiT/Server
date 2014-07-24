class Api::V1::AccesscodesController < ApplicationController
  
  def new 
  end

  def show
  	accesscode = Accesscode.where(code: params[:id]).take
  	accesscode.kvalue = (accesscode.kvalue + 1)
  	accesscode.save

  	if (accesscode.kvalue < 5)
  		render json: {code: accesscode}
    else
      render json: { error: { code: ERROR_UNAUTHORIZED, messages: ["code used too often"] } }, status: :unauthorized 
  	end
  end
 
  def create
  	@accesscode = Accesscode.new(accesscodes_params)
  end

  private 

  def accesscodes_params
  		params.require(:accesscode).permit(:code, :kvalue)
  end
end
