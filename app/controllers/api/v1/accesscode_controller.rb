#The reason this is in the api/v1/ folder is because it is a controller used for the actual app 
#Controllers in the "controllers/" file are controllers used for the administrative tool (or so we think),
# a fucking comment would have been nice.

#Defines a class called AccessCodeController with one method
#That method checks the kvalue of the accesscode passed to it
#it returns this kvalue, all processing to determine the validity
#of the kvalue is done on the client side, lightens burden on serverside

class  Api::V1::AccessCodeController < ApiBaseController

  def get_accesscode_from_table

    @code = AccessCode.new
    @code.accesscode = params[:access_code] #select the stuff that is passed from LTServer.m#
    @code.kvalue = @code.find(@code.accesscode).kvalue  #select the stuff that is passed from LTServer.m#
    #we can do this because .find() returns an object, the object for this table is an accesscode, so .find() returns an access code#

    #puts @code.kvalue

    if @code.save
      render json: @code.kvalue

    else
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["AccessCode #{params[:access_code]} not found"] } }, status: :not_found
    end

  end

end

