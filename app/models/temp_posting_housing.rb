class TempPostingHousing < ActiveRecord::Base
  #validates :comment, presence: true

  belongs_to :user
  belongs_to :venue

end
