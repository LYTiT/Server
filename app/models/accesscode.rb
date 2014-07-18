class AccessCode < ActiveRecord::Base

#Check id the passed code existes and is not too long

  validates_length_of :accesscode, :within => 1..5

end
