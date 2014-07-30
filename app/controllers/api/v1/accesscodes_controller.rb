class Api::V1::AccesscodesController < ApplicationController
<<<<<<< HEAD
	respond_to :json	
=======
  respond_to :json
>>>>>>> 571a7eceed89450725313f0fe6ff7987dbd9bb6c

  def new 
  end
  
  #Checks if the entered accesscode is used less than 5 times.
  #def show
  #	accesscode = Accesscode.where(code: params[:id]).take
  #	accesscode.kvalue = accesscode.kvalue + 1
  #	accesscode.save
  #	if (accesscode.kvalue < 5 )
  #	  render json: {code: accesscode}
  #	end
  #end

  def show
    @accesscode = Accesscode.where(code: params[:id]).take
    @accesscode.kvalue = @accesscode.kvalue+1
    @accesscode.save
<<<<<<< HEAD
=======
    #@accesscode = Accesscode.where(code: params[:id]).take
    #accesscode = @accesscode.as_json
>>>>>>> 571a7eceed89450725313f0fe6ff7987dbd9bb6c
    render json: @accesscode.as_json
  end

  #def update
  #end

  #def create
  #	@accesscode = Accesscode.new(accesscode_params)
  #end

  #private 
  def accesscode_params
  	params.require(:accesscode).permit(:code, :kvalue)
  end
end
