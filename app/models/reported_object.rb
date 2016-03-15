class ReportedObject < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment
	belongs_to :feed
	belongs_to :reporter, class_name: "User"

end