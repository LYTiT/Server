class Group < ActiveRecord::Base
  validates :name, presence: true  
  validates_inclusion_of :is_public, in: [true, false]
  validates :password, presence: true, :if => :should_validate_password?
  validates :user, presence: true
  validates :venue, presence: true

  belongs_to :user # group admin
  belongs_to :venue

  def should_validate_password?
  	not is_public
  end
end
