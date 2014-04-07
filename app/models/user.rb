class User < ActiveRecord::Base
  include Clearance::User

  has_many :venue_ratings

  before_save :ensure_authentication_token

  private

  def ensure_authentication_token
    self.authentication_token ||= SecureRandom.hex
  end
end
