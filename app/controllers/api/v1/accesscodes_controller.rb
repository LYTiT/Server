class Api::V1::AccesscodesController < ApplicationController
	respond_to :json	

  def new 
  end

  def show
    @accesscode = Accesscode.where(code: params[:id]).take
    @accesscode.kvalue = @accesscode.kvalue+1
    @accesscode.save
    #@accesscode = Accesscode.where(code: params[:id]).take
    #accesscode = @accesscode.as_json
    render json: @accesscode.as_json
  end

  #private 
  def accesscode_params
  	params.require(:accesscode).permit(:code, :kvalue)
  end
end
