#this just declares the accesscode object as a model
#This just declares the accesscode object as a model
#the model has two fields, accesscode and kvalue
class AccessCode < ActiveRecord::Base

  validates :accesscode, presence: true
  validates :kvalue, presence: true
  validates_length_of :accesscode, :within => 1..5
end
