class User < ActiveRecord::Base
  include Clearance::User

  has_many :venue_ratings
  has_many :venue_comments

  before_save :ensure_authentication_token

  # This is to deal with S3.
  def email_with_id
    "#{email}-#{id}"
  end

  private

  def ensure_authentication_token
    self.authentication_token ||= SecureRandom.hex
  end
end
