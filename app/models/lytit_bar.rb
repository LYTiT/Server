class LytitBar < ActiveRecord::Base
  include Singleton

  validates :position, presence: true
end
