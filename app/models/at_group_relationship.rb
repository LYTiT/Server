class AtGroupRelationship < ActiveRecord::Base
	belongs_to :venue_comment
	belongs_to :group
	validates :venue_comment_id, presence: true
	validates :group_id, presence: true

	#after_create :new_at_group_notification
end