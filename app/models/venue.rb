class Venue < ActiveRecord::Base
  validates :name, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true

  has_many :venue_ratings
  has_many :venue_comments
  has_many :groups

  def self.search(params)

    scoped = all

    if params[:lat] && params[:lng]
      search = Search.new(params[:lat], params[:lng])
      scoped.where!("latitude < '#{search.ne_lat}' AND latitude > '#{search.sw_lat}'")
      scoped.where!("longitude < '#{search.ne_lng}' AND longitude > '#{search.sw_lng}'")
    end

    scoped
  end
end
