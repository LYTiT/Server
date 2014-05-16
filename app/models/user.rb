class User < ActiveRecord::Base
  include Clearance::User

  validates_uniqueness_of :email, :case_sensitive => false

  has_many :venue_ratings, :dependent => :destroy
  has_many :venue_comments, :dependent => :destroy
  has_many :groups_users, :dependent => :destroy
  has_many :groups, through: :groups_users

  has_many :flagged_comments, :dependent => :destroy

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
