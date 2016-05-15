class CommentView < ActiveRecord::Base

  belongs_to :venue_comment
  belongs_to :user

  validates :venue_comment, presence: true
  validates :user, presence: true
  #validates_uniqueness_of :user_id, :scope => :venue_comment_id, message: "has all ready viewed this post"

  #after_create :send_new_views_notification

  def send_new_views_notification
  	vc = self.venue_comment
    vc_user = vc.user
  	if vc.num_enlytened == 1 || (vc.num_enlytened%5 == 0 && vc.num_enlytened <= 20) || (vc.num_enlytened%10 && vc.num_enlytened > 20)
      payload = {
        :intended_for => self.venue_comment.user_id,
        :object_id => self.id,       
        :type => 'moment_views_notification',
        :venue_comment_id => vc.id,
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
        :venue_address => vc.venue_details["address"],
        :venue_city => vc.venue_details["city"],
        :venue_country => vc.venue_details["country"],
        :latitude => vc.venue_details["latitdue"],
        :longitude => vc.venue_details["longitude"],
        :timestamp => vc.created_at.to_i,
        :content_origin => 'lytit',
        :num_views => vc.num_enlytened,
        :num_enlytened => vc.num_enlytened
      }

      type = "comment_view/#{vc.id}"
      


      notification = Notification.where(type: type).first || self.store_new_notification(payload, vc_user, type)

      payload[:notification_id] = notification.id

      if vc.num_enlytened == 1
        preview = "Your post at #{vc.venue_details["name"]} has enlytened a person!"
      elsif vc.num_enlytened > 1 && vc.num_enlytened <= 20
        preview = "+5 more people enlytened!"
      else
        preview = "+10 more people enlytened!"
      end

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

  def CommentView.assign_views
    lytit_posts = VenueComment.where("entry_type = ? AND created_at > ?", "lytit_post", Time.now-24.hours)

    for lytit_post in lytit_posts
      #CommentView.auto_view_generator(lytit_post)      
    end
  end

  def CommentView.auto_view_generator(lytit_post, total_sim_user_base=50000)
    #NEEDS TO TAKE INTO CONSIDERATION LOCAL TIME OF DAY
    venue = lytit_post.venue
    venue_rating = venue.rating || (rand(5) >=3 ? 0 : 0.0005)

    num_surrounding_users = User.where("latitude IS NOT NULL").close_to(venue.latitude, venue.longitude, 20000).count
    total_users = User.where("latitude IS NOT NULL").count
    
    num_simulated_users = (total_sim_user_base * (num_surrounding_users.to_f/(total_users.to_f+1.0)) - lytit_post.views) * venue_rating/1000.0 + ((rand(2) == 0 ? 1 : -1) * rand(10))

    num_preceeding_posts = venue.venue_comments.where("adjusted_sort_position > ?", lytit_post.adjusted_sort_position).count

    num_simulted_views = (num_simulated_users * (1 - num_preceeding_posts*0.01)).floor

    for i in 1..num_simulted_views
      lytit_post.user.increment!(:num_bolts, 1)

      nearby_venue = Venue.close_to(venue.latitude, venue.longitude, 20000).first
      faraway_venue = Venue.far_from(venue.latitude, venue.longitude, 20000).offset(rand(1000)).first rescue Venue.far_from(venue.latitude, venue.longitude, 20000).first
      selected_venue = (rand(99) < 96 ? nearby_venue : faraway_venue) 
      country = selected_venue.country
      city = selected_venue.city
      lytit_post.increment_geo_views(country, city)

      view = CommentView.delay(run_at: rand(900).seconds.from_now).create!(:venue_comment_id => lytit_post.id, :user_id => 1)
    end
  end

end
