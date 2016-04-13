class CommentView < ActiveRecord::Base

  belongs_to :venue_comment
  belongs_to :user

  validates :venue_comment, presence: true
  validates :user, presence: true
  validates_uniqueness_of :user_id, :scope => :venue_comment_id, message: "has all ready viewed this post"

  after_create :send_new_views_notification

  def send_new_views_notification
  	vc = self.venue_comment
    vc_user = vc.user
  	if vc.views == 1 || (vc.views%5 == 0 && vc.views <= 20) || (vc.views%10 && vc.views > 20)
      payload = {
        :object_id => self.id,       
        :type => 'moment_views_notification',
        :id => vc.id,
        :media_type => vc.lytit_post["media_type"],
        :media_dimensions => vc.lytit_post["media_dimensions"],
        :image_url_1 => vc.lytit_post["image_url_1"],
        :image_url_2 => vc.lytit_post["image_url_2"],
        :image_url_3 => vc.lytit_post["image_url_3"],
        :video_url_1 => vc.lytit_post["video_url_1"],
        :video_url_2 => vc.lytit_post["video_url_2"],
        :video_url_3 => vc.lytit_post["video_url_3"],
        :venue_id => vc.venue_details["id"],
        :venue_name => vc.venue_details["name"],
        :latitude => vc.venue_details["latitdue"],
        :longitude => vc.venue_details["longitude"],
        :timestamp => vc.created_at,
        :content_origin => 'lytit',
        :geo_views => vc.geo_views,
        :num_views => vc.views
      }

      type = "comment_view/#{vc.id}/#{vc.views}"

      notification = self.store_new_notification(payload, vc_user, type)
      payload[:notification_id] = notification.id

      if vc_user.push_token && vc_user.active == true
        count = Notification.where(user_id: vc_user.id, read: false, deleted: false).count
        APNS.send_notification(vc_user.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count})
      end
  	end
  end

  def store_new_notification(payload, notification_user, type)
    notification = {
      :payload => payload,
      :gcm => notification_user.gcm_token.present?,
      :apns => notification_user.push_token.present?,
      :response => nil,
      :user_id => notification_user.id,
      :read => false,
      :message => type,
      :deleted => false
    }
    Notification.create(notification)
  end  

end
