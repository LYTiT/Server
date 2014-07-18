#This just declares the accesscode object as a model
#the model has two fields, accesscode and kvalue
class AccessCode < ActiveRecord::Base

  validates :accesscode, :kvalue

end

