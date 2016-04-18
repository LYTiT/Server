class ReportedObject < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment
	belongs_to :feed
	belongs_to :reporter, class_name: "User"

	after_create :evaluate_report

	def evaluate_report
		if type == "Reported Post"
			num_reports = self.venue_comment.reported_objects.count
			num_total_views = self.venue_comment.comment_views.count
			
			if (num_total_views > 5 && num_reports.to_f/num_total_views.to_f >= 0.5 && venue_comment.visible == true)
				venue_comment.update_columns(visible: false)
				previous_violations = user.violations				
				user.update_columns(violations: {"#{Time.now}" => type}.merge!(previous_violations))
				#send notification
			end
		end
	end

end