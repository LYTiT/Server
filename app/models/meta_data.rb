class MetaData < ActiveRecord::Base
	belongs_to :venue
	belongs_to :venue_comment
end