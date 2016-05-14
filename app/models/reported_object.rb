class ReportedObject < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment
	belongs_to :feed
	belongs_to :activity_comment
	belongs_to :reporter, class_name: "User"

	after_create :evaluate_report

	def evaluate_report
		if report_type == "Reported Post"
			num_reports = self.venue_comment.reported_objects.count
			num_total_views = self.venue_comment.evaluater_user_ids.count

			if (num_total_views > 8 && num_reports.to_f/num_total_views.to_f >= 0.5 && venue_comment.adjusted_sort_position != -1)
				venue_comment.update_columns(adjusted_sort_position: -1)
				previous_violations = user.violations				
				user.update_columns(violations: {"#{Time.now}" => report_type}.merge!(previous_violations))


				user_support_issue = user.support_issue
				if user_support_issue != nil				
					support_issue = user_support_issue
					support_issue_id = user_support_issue.id
				else
					support_issue = SupportIssue.create!(:user_id => @user.id)
					support_issue_id = new_support_issue.id
				end

				message = "It appears you have posted an inappropriate #{venue_comment.lytit_post["media_type"]} at #{venue_comment.venue_details["name"]}. As a result, your posting
				privileges will be revoked for #{user.violations.values.count("Reported Post")*2} hours. If you believe this is an error, you may respond to this message. Repeat offenses 
				may result in suspension of your Lytit usage rights."
				sm = SupportMessage.create!(:message => message, :support_issue_id => support_issue_id, :user_id => user.id)
			end
		end

		if report_type == "Activity Comment"
			num_reports = self.activity_comment.reported_objects.count

			if num_reports > 10
				self.activity_comment.delete
			end
		end
	end

end