class Role < ActiveRecord::Base
  
  validates_uniqueness_of :name, :case_sensitive => false
  validates :name, presence: true
  
end
