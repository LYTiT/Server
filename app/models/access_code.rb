class AccessCode < ActiveRecord::Base

#Check id the passed code existes and is not too long
#Check if there is a k-value attached to the passed code

  validates :accesscode, presence: true
  validates :kvalue, presence: true

  validates_length_of :accesscode, :within => 1..5

end
