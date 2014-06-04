class VenueMessage < ActiveRecord::Base

  belongs_to :venue

  default_scope { order(:position) } 

  validates :message, presence: true
  validates :message, length: { maximum: 60 }
  validates :position, numericality: true
  validates :venue, presence: true

end
