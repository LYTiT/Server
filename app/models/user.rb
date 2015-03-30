class User < ActiveRecord::Base
  include Clearance::User

  attr_accessor :password_confirmation

  validates_uniqueness_of :name, :case_sensitive => false
  validates :name, presence: true, format: { with: /\A(^@?(\w){1,15}$)\Z/i}
  validates :venues, presence: true, if: Proc.new {|user| user.role.try(:name) == "Venue Manager"}
  validates :venues, absence: true, if: Proc.new {|user| user.role.try(:name) != "Venue Manager"}
  validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  validates_length_of :password, :minimum => 8, unless: :skip_password_validation?

  has_many :venue_ratings, :dependent => :destroy
  has_many :venue_comments, :dependent => :destroy
  has_many :groups_users, :dependent => :destroy
  has_many :groups, through: :groups_users
  has_many :flagged_comments, :dependent => :destroy
  has_many :venues
  
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :relationships, source: :followed
  has_many :reverse_relationships, foreign_key: "followed_id", class_name: "Relationship", dependent: :destroy
  has_many :followers, through: :reverse_relationships, source: :follower
  
  has_many :venue_relationships, foreign_key: "ufollower_id", dependent: :destroy
  has_many :followed_venues, through: :venue_relationships, source: :vfollowed

  has_many :reverse_group_invitations, foreign_key: "invited_id", class_name: "GroupInvitation",  dependent: :destroy
  has_many :igroups, through: :reverse_group_invitations, source: :igroup

  has_many :lumen_values, :dependent => :destroy

  has_many :announcement_users, :dependent => :destroy
  has_many :announcements, through: :announcement_users

  has_many :temp_posting_housings, :dependent => :destroy

  has_many :bounties, :dependent => :destroy

  belongs_to :role

  before_save :ensure_authentication_token
  before_save :generate_confirmation_token_for_venue_manager
  after_save :notify_venue_managers
  
  #clear all outstanding user lumens
  def self.global_lumen_recalibration
    LumenValue.delete_all
    all = User.all
    for person in all
      person.lumens = 0.0
      person.video_lumens = 0.0
      person.image_lumens = 0.0
      person.text_lumens = 0.0
      person.vote_lumens = 0.0
      person.lumen_percentile = 0.0
      person.save
    end
  end

  # This is to deal with S3.
  def email_with_id
    "#{email}-#{id}"
  end

  def set_version(v)
    update_columns(version: v)
  end

  def toggle_group_notification(group_id, enabled)
    group_user = GroupsUser.where("group_id = ? and user_id = ?", group_id, self.id).first
    if group_user
      group_user.update(:notification_flag => (enabled == 'yes' ? true : false))
      return true
    else
      return false, 'You are not member of this group'
    end
  end

  def is_venue_manager?
    role.try(:name) == "Venue Manager"
  end

  def is_admin?
    role.try(:name) == "Admin"
  end

  def version_compatible?(ver)
    version_split = self.version.split(".")
    v0 = version_split[0].to_i
    u0 = version_split[1].to_i || 0
    p0 = version_split[2].to_i || 0 

    target_version = ver.split(".")
    v1 = target_version[0].to_i
    u1 = target_version[1].to_i || 0
    p1 = target_version[2].to_i || 0

    if v0 > v1 
      return true
    elsif v0 >= v1 && u0 > u1
      return true
    elsif (v0 >= v1 && u0 >= u1) && (p0 >= p1)
      return true
    else
      return false
    end

  end

  def manages_any_venues?
    venues.size > 0
  end

  def send_location_added_to_group_notification?(group)
    self.notify_location_added_to_groups and GroupsUser.send_notification?(group.id, self.id)
  end

  def send_event_added_to_group_notification?(group)
    self.notify_events_added_to_groups and GroupsUser.send_notification?(group.id, self.id)
  end

  def following?(other_user)
    relationships.find_by(followed_id: other_user.id) ? true : false
  end
  #follows a user
  def follow!(other_user)
    relationships.create!(followed_id: other_user.id)
  end

  def unfollow!(other_user)
    relationships.find_by(followed_id: other_user.id).destroy
  end

  #follows a venue
  def vfollow!(venue)
    venue_relationships.create!(vfollowed_id: venue.id)
  end

  def vunfollow!(venue)
    venue_relationships.find_by(vfollowed_id: venue.id).destroy
  end

  def vfollowing?(venue)
    venue_relationships.find_by(vfollowed_id: venue.id) ? true : false
  end

=begin THIS IS THE OLD FEED IMPLEMENTATOIN THAT WAS ABANDONDED DUE TO MEMORY INEFFICIENCY
  def groupfeed
    #List of the ids of Groups user is part of
    group_ids = self.groups.flatten.map(&:id)
    #User not part of any Group thus there can be no feed
    if group_ids.length == 0
      return nil
    else
      #To prevent redundent entries in the Moments feed will omit Venue Comments pulled from places and people the user follows
      excluded_ids = (VenueComment.from_users_followed_by(self)<<VenueComment.from_venues_followed_by(self)).flatten.map(&:id).join(', ')
      valid_ids = ''
      for g_id in group_ids
        #We check to make sure the user is subscribed to the Group before pullings its associated Venue Comments
        if GroupsUser.where("user_id = #{id} AND group_id = #{g_id}").first.notification_flag == false
          next
        else
          considered_group = Group.find_by_id(g_id)
          if excluded_ids.length > 0
            at_group_valid_venue_comment_ids = "SELECT venue_comment_id FROM at_group_relationships WHERE group_id = #{g_id} AND venue_comment_id NOT IN (#{excluded_ids})"
            mapped_at_group_valid_venue_comment_ids = VenueComment.where("id IN (#{at_group_valid_venue_comment_ids})").map(&:id).join(', ')
          else
            at_group_valid_venue_comment_ids = "SELECT venue_comment_id FROM at_group_relationships WHERE group_id = #{g_id}"
            mapped_at_group_valid_venue_comment_ids = VenueComment.where("id IN (#{at_group_valid_venue_comment_ids})").map(&:id).join(', ')
          end
          valid_ids << mapped_at_group_valid_venue_comment_ids #these Venue Comments are the @Group comments of the Group that are not part of the followed people or places feed
          
          #We pull in the associated Venue Comments of a Group (Venue Comments posted at Venues belonging to the Group)
          if excluded_ids.length > 0
            group_venue_ids = "SELECT venue_id FROM groups_venues WHERE group_id = #{g_id}"
            gfeed_vc_ids = VenueComment.where("venue_id IN (#{group_venue_ids}) AND user_id != #{self.id} AND id NOT IN (#{excluded_ids})").flatten.map(&:id).join(', ')
          else
            group_venue_ids = "SELECT venue_id FROM groups_venues WHERE group_id = #{g_id}"
            gfeed_vc_ids = VenueComment.where("venue_id IN (#{group_venue_ids}) AND user_id != #{self.id}").flatten.map(&:id).join(', ')
          end

          #Prevent double pulling of Venue Comments that belong to more than one Group (if for example the Venue Comment's venue belongs to both Groups)
          if gfeed_vc_ids.length > 0
            if valid_ids.length >0
              valid_ids = valid_ids + ', ' + gfeed_vc_ids
              exlcuded_ids = excluded_ids + ', ' + valid_ids
            else
              valid_ids = gfeed_vc_ids
              exlcuded_ids = valid_ids
            end
          end
        end
      end
      #Return the final list of Venue Comments if there is something new to return
      if valid_ids.length > 0 
        gfeed = VenueComment.where("id IN (#{valid_ids})")
        type = Array.new(gfeed.count, 2)
        return gfeed.zip(type.to_a)
      else
        return nil
      end
    end
  end

  def userfeed
    ufeed = VenueComment.from_users_followed_by(self)
    type = Array.new(ufeed.count, 1)
    ufeed.zip(type.to_a)
  end

  def venuefeed
    vfeed = VenueComment.from_venues_followed_by(self)
    type = Array.new(vfeed.count, 0)
    vfeed.zip(type.to_a)
  end

  #2D array containing arrays composed of a venue comment and a flag to determine the comments source (from followed user or venue)
  def old_totalfeed
    feed = (userfeed + venuefeed + groupfeed)
    feed_sorted = feed.sort_by{|x,y| x.created_at}.reverse
  end
=end


  def totalfeed
    ids_of_followed_users = "SELECT followed_id FROM relationships WHERE follower_id = #{self.id}"
    ids_of_followed_venues = "SELECT vfollowed_id FROM venue_relationships WHERE ufollower_id = #{self.id}"
    ids_of_subscribed_groups = "SELECT group_id FROM groups_users WHERE (user_id = #{self.id} AND notification_flag = 'true')"
    ids_of_groups_venues = "SELECT venue_id FROM groups_venues WHERE group_id IN (#{ids_of_subscribed_groups})"

    at_group_valid_venue_comment_ids = "SELECT venue_comment_id FROM at_group_relationships WHERE group_id IN (#{ids_of_subscribed_groups})"

    feed = VenueComment.where("(user_id IN (#{ids_of_followed_users}) AND username_private = 'false')
      OR (venue_id IN (#{ids_of_followed_venues}) AND user_id NOT IN (#{ids_of_followed_users})) AND user_id != #{self.id}
      OR (venue_id IN (#{ids_of_groups_venues}) AND venue_id NOT IN (#{ids_of_followed_venues}) AND user_id NOT IN (#{ids_of_followed_users}) AND user_id != #{self.id})
      OR (id IN (#{at_group_valid_venue_comment_ids}) AND venue_id NOT IN (#{ids_of_followed_venues}) AND venue_id NOT IN (#{ids_of_groups_venues}) AND user_id NOT IN (#{ids_of_followed_users}) AND user_id != #{self.id})").order("Id DESC").uniq
  end

  def surrounding_feed(lat, long)
    meter_radius = 750
    #nearby_venues = Venue.within(Venue.meters_to_miles(meter_radius.to_i), :origin => [lat, long]).order('distance ASC')

    min_lat = lat.to_f - ((meter_radius.to_i) * (284.0 / 160.0)) / (109.0 * 1000)
    max_lat = lat.to_f + ((meter_radius.to_i) * (284.0 / 160.0)) / (109.0 * 1000)
    min_long = long.to_f - meter_radius.to_i / (113.2 * 1000 * Math.cos(lat.to_f * Math::PI / 180))
    max_long = long.to_f + meter_radius.to_i / (113.2 * 1000 * Math.cos(lat.to_f * Math::PI / 180))
    venue_ids = "SELECT id FROM venues WHERE latitude >= #{min_lat} AND latitude <= #{max_lat} AND longitude >= #{min_long} AND longitude <= #{max_long}"

    surrounding_moments = VenueComment.where("venue_id IN (#{venue_ids}) AND bounty_claim_id IS NULL AND created_at >= ?", (Time.now - 2.days))
    surrounding_moment_requests = Bounty.where("venue_id IN (#{venue_ids}) AND created_at >= ?", (Time.now - 2.days))
    surrounding_moment_request_responses = BountyClaim.joins(:venue_comment).where("venue_id IN (#{venue_ids}) AND created_at >= ?", (Time.now - 2.days))

=begin    
    for v in nearby_venues
      if v.city != nil
        venue = v
        break
      end
    end

    if venue.l_sphere != nil
      current_sphere = venue.l_sphere
    else
      current_sphere = venue.city.delete(" ")+(venue.latitude.round(0).abs).to_s+(venue.longitude.round(0).abs).to_s
      venue.l_sphere = current_sphere
      venue.save
    end

    surrounding_moment_requests = Bounty.joins(:venue).where('l_sphere = ?', current_sphere)
    surrounding_moment_request_responses = BountyClaim.joins(venue_comment: :venue).where('l_sphere = ?', current_sphere)
    surrounding_moments = VenueComment.joins(:venue).where('l_sphere = ?', current_sphere).where('bounty_claim_id IS NULL')
=end

    feed = (surrounding_moment_requests + surrounding_moment_request_responses + surrounding_moments)
    surrounding_feed = feed.sort_by{|x,y| x.created_at}.reverse
  end

  #Returns users sorted in alphabetical order that are not in a group. We also omit users that have already received an invitation to join the Group.
  def followers_not_in_group(group_id)
    users_in_group = "SELECT user_id FROM groups_users WHERE group_id = #{group_id}"
    followers_ids = "SELECT follower_id FROM relationships WHERE followed_id = #{self.id}"
    User.where("id IN (#{followers_ids}) AND id NOT IN (#{users_in_group})").order("Name ASC")
  end

  #Returns list of Groups user is a member of which ar linkable to a Venue Page (either linkable xor admin of)
  def linkable_groups
    all_groups_ids = "SELECT group_id FROM groups_users WHERE user_id = #{self.id}"
    admin_groups_ids = "SELECT group_id FROM groups_users WHERE user_id = #{self.id} AND is_admin = true"
    Group.where("(id IN (#{all_groups_ids}) AND can_link_venues = true) OR id IN (#{admin_groups_ids})").order("Name ASC")
  end


  #Has the user been invited to a the Group "group"?
  def invited?(group_id)
    reverse_group_invitations.find_by(igroup_id: group_id) ? true : false
  end

  #Lumens are acquired only after voting or posted content receives a view
  def update_lumens_after_vote(id)
    new_lumens = LumenConstants.votes_weight_adj
    updated_lumens = self.lumens + new_lumens

    vt_l = self.vote_lumens
    update_columns(vote_lumens: (vt_l + new_lumens).round(4))

    update_columns(lumens: updated_lumens)
    #update_lumen_percentile

    l = LumenValue.new(:value => new_lumens.round(4), :user_id => self.id, :lytit_vote_id => id)
    l.save
  end

  def update_lumens_after_text(text_id)
    id = text_id
    new_lumens = LumenConstants.text_media_weight
    updated_lumens = self.lumens + new_lumens

    t_l = self.text_lumens
    update_columns(text_lumens: (t_l + new_lumens).round(4))

    update_columns(lumens: updated_lumens)
    #update_lumen_percentile

    l = LumenValue.new(:value => new_lumens.round(4), :user_id => self.id, :venue_comment_id => id, :media_type => "text")
    l.save
  end

  def update_lumens_after_view(comment)
    if self.adjusted_view_discount == nil
      self.adjusted_view_discount = LumenConstants.views_weight_adj_damping
      save
    end

    id = comment.id
    time = Time.now
    comment_time = comment.created_at
    time_delta = ((time - comment_time) / 1.minute) / (LumenConstants.views_halflife)
    adjusted_view = 2.0 ** (-time_delta)
    
    previous_lumens = self.lumens
    new_lumens = comment.consider*(comment.weight*adjusted_view*LumenConstants.views_weight_adj).round(4)
    updated_lumens = previous_lumens + new_lumens

    if comment.media_type == 'video'
      v_l = self.video_lumens
      update_columns(video_lumens: (v_l + new_lumens).round(4))
    else
      i_l = self.image_lumens
      update_columns(image_lumens: (i_l + new_lumens).round(4))
    end

    update_columns(lumens: updated_lumens.round(4))
    #update_lumen_percentile

    if new_lumens > 0
      l = LumenValue.new(:value => new_lumens.round(4), :user_id => self.id, :venue_comment_id => id, :media_type => comment.media_type)
      l.save
    end
  end

  def adjust_lumens
    adjusted_total_lumens = (self.lumens - LumenConstants.text_media_weight).round(4)
    adjusted_text_lumens = (self.text_lumens - LumenConstants.text_media_weight).round(4)

    update_columns(lumens: adjusted_total_lumens)
    update_columns(text_lumens: adjusted_text_lumens)
  end

   #Lumen Calculation########################################################################################
  def populate_lumens()
    comments = self.venue_comments
    v_lumens = 0
    i_lumens = 0
    t_lumens = 0
    vt_lumens = self.total_votes*LumenConstants.votes_weight_adj
    
    lumens = vt_lumens 

    comments.each do |comment|
      if comment.media_type == 'video'
        v_lumens += comment.consider*(comment.weight*comment.adj_views*LumenConstants.views_weight_adj)
      elsif comment.media_type == 'image'
        i_lumens += comment.consider*(comment.weight*comment.adj_views*LumenConstants.views_weight_adj)
      else
        t_lumens += comment.consider*(comment.weight)
      end
    end

      update_columns(video_lumens: v_lumens.round(4))
      update_columns(image_lumens: i_lumens.round(4))
      update_columns(text_lumens: t_lumens.round(4))
      update_columns(vote_lumens: vt_lumens.round(4))

      update_columns(lumens: (v_lumens + i_lumens + t_lumens + vt_lumens).round(4))
  end

  #Extract acquired Lumens for user on a particulare date
  def lumens_on_date(date)
   lumens_of_date = LumenValue.where("user_id = ? AND created_at <= ? AND created_at >= ?", self.id, date.at_end_of_day, date.at_beginning_of_day)
   lumens_of_date.inject(0) { |sum, l| sum + l.value}
  end

  def weekly_lumens
    t_1 = (Time.now - 6.days)
    t_2 = t_1 + 1.days
    t_3 = t_2 + 1.days
    t_4 = t_3 + 1.days
    t_5 = t_4 + 1.days
    t_6 = t_5 + 1.days
    t_7 = t_6 + 1.days

    weekly_lumens = [lumens_on_date(t_1).round(4), lumens_on_date(t_2).round(4), lumens_on_date(t_3).round(4), lumens_on_date(t_4).round(4), lumens_on_date(t_5).round(4), lumens_on_date(t_6).round(4), lumens_on_date(t_7).round(4)]
  end

  #Constructs array of color values which determine which coloor to assign to particular weekly Lumen value on the front-end.
  def weekly_lumen_color_values(weekly_lumens)
    color_values = [] 
    weekly_lumens.each {|l| color_values << color_value_assignment(l)}
    color_values
  end

  #Determining color values for daily lumens. 0 is no Lumens which corresponds to an empty circle, 7 is white.
  def color_value_assignment(value)
    rvalue = value.ceil
    if rvalue == 0
      0
    elsif rvalue.between?(0.00001, 2.0)
      1
    elsif rvalue.between?(2.00001, 7.0)
      2
    elsif rvalue.between?(7.00001, 16.0)
      3
    elsif rvalue.between?(16.00001, 32.0)
      4
    elsif rvalue.between?(32.00001, 64.0)
      5
    elsif rvalue.between?(64.00001, 128.0)
      6
    else 
      7
    end
  end

  #2-D array containing the Lumen value of a day and the corresponding color value
  def lumen_package
    package = weekly_lumens.zip(weekly_lumen_color_values(weekly_lumens))
  end

  #Extract Lumen Values for each user by instance and create according Lume Value objects. This is to backfill historical Lumen values.#########################
  def populate_lumen_values 
    votes = LytitVote.where(user_id: self.id)
    for vote in votes
      l = LumenValue.new(:value => LumenConstants.votes_weight_adj, :user_id => self.id, :lytit_vote_id => vote.id)
      l.created_at = vote.created_at
      l.save
    end

    comments = self.venue_comments
    for comment in comments
      if comment.media_type == 'text' and comment.consider? == 1
        l2 = LumenValue.new(:value => comment.weight, :user_id => self.id, :venue_comment_id => comment.id, :media_type => 'text')
        l2.created_at = comment.created_at
        l2.save
      else
        views = CommentView.where("venue_comment_id = ? and user_id != ?", comment.venue_id, self.id)
        for view in views
          adjusted_views = 2 ** ((- (view.created_at - comment.created_at) / 1.minute) / (LumenConstants.views_halflife))
          l3 = LumenValue.new(:value => (comment.consider*(comment.weight*adjusted_views*LumenConstants.views_weight_adj)).round(4), :user_id => self.id, :venue_comment_id => comment.id, :media_type => comment.media_type)
          l3.created_at = view.created_at
          l3.save
        end
      end
    end
  end

  def lumen_percentile_calculation
    all_lumens = User.all.map { |user| user.lumens}
    percentile = all_lumens.percentile_rank(self.lumens)
  end

  ############################################################################################################################################################
  def update_lumen_percentile
    if self.lumens == 0
      update_columns(lumen_percentile: 0)
    else
      all_lumens = User.all.map { |user| user.lumens}
      percentile = all_lumens.percentile_rank(self.lumens)
      update_columns(lumen_percentile: percentile)
    end
  end

  def lumen_rank #we update the percentile everytime we check rank
    total_number = User.count
    rank = User.count(:conditions => ['lumens > ?', self.lumens])+1
    self.lumen_percentile = ((rank.to_f+1.0)/(total_number.to_f+1.0))*100.0
    self.save
    return rank 
  end

  def total_votes
    LytitVote.where(user_id: self.id).count
  end

  def total_video_comments
    VenueComment.where(user_id: self.id, media_type: "video").count
  end

  def total_image_comments
    VenueComment.where(user_id: self.id, media_type: "image").count
  end

  def total_text_comments
    VenueComment.where(user_id: self.id, media_type: "text").count
  end

  def populate_total_views
    count = 0
    comments = VenueComment.where(user_id: self.id, media_type: "video").append(VenueComment.where(user_id: self.id, media_type: "image")).flatten!
    comments.each {|comment| count += comment.total_views}
    update_columns(total_views: count)
  end

  def update_total_views
    current = total_views
    update_columns(total_views: (current + 1) )
  end

  #averager number of adjusted views received
  def avg_adj_views
    comments = self.venue_comments
    total_adjusted_views = 0
    total_considered_comments = 0

    comments.each do |comment|
      if comment.consider == 1
        total_adjusted_views += comment.adj_views
        total_considered_comments += 1
      end
    end

    total_adjusted_views -= total_text_comments*LumenConstants.text_media_weight
    if total_considered_comments > 0
      average_adj_views = total_adjusted_views / total_considered_comments
    else
      average_adj_views = 0
    end

    average_adj_views
  end


  #Radius assignment to Lumen contributing categories for Lumen breakout screen
  def radius_assignment
    radii = Hash.new

    if self.lumens < 1
      radii["video"] = 0.0
      radii["image"] = 0.0
      radii["text"] = 0.0
      radii["votes"] = 0.0
      radii["bounty"] = 0.0
      return radii
    else
      perc = (100-lumen_percentile) || 91

      if perc.between?(0, 10)
        span = 100
      elsif perc.between?(11, 20)
        span = 105
      elsif perc.between?(21, 30)
        span = 110
      elsif perc.between?(31, 40)
        span = 115
      elsif perc.between?(41, 50)
        span = 120
      elsif perc.between?(51, 60)
        span = 125
      elsif perc.between?(61, 70)
        span = 135
      elsif perc.between?(71, 80)
        span = 140 
      elsif perc.between?(81, 90)
        span = 145
      else
        span = 150
      end

      total_lumens = []
      total_lumens << video_lumens
      total_lumens << image_lumens
      total_lumens << text_lumens
      total_lumens << vote_lumens
      total_lumens << bounty_lumens

      min_lumen = total_lumens.min

      range = (span - 65)/ (1 + (min_lumen / self.lumens))
      radius = span - range

      radii["video"] = (video_lumens / self.lumens) * range + radius
      radii["image"] = (image_lumens / self.lumens) * range + radius
      radii["text"] = (text_lumens / self.lumens) * range + radius
      radii["votes"] = (vote_lumens / self.lumens) * range + radius
      radii["bounty"] = (bounty_lumens / self.lumens) * range + radius

      radii2 = Hash[radii.sort_by {|k, v| v}]
      return radii2
    end
  end

  def video_radius
    radius_assignment["video"]
  end

  def image_radius
    radius_assignment["image"]
  end
  
  def text_radius
    radius_assignment["text"]
  end

  def votes_radius
    radius_assignment["votes"]
  end

  def bounty_radius
    radius_assignment["bounty"]
  end

  def views_radius
    if total_views == 0
      70
    else
      [Math::log(total_views) + 75, 85].min
    end
  end

  #Used for color assignment of Lumen contribution categories in the Lumen breakout screen
  def lumen_video_contribution_rank
    rank = radius_assignment.keys.index("video") + 1
  end

  def lumen_image_contribution_rank
    rank = radius_assignment.keys.index("image") + 1 
  end

  def lumen_text_contribution_rank
    rank = radius_assignment.keys.index("text") + 1
  end

  def lumen_votes_contribution_rank
    rank = radius_assignment.keys.index("votes") + 1
  end

  def lumen_bounty_contribution_rank
    rank = radius_assignment.keys.index("bounty") + 1
  end 

  def lumen_views_contribution_rank
    return 5
  end 

  #Average views received per photo/video posting, i.e are Lumens coming from popularity or posting frequency
  def view_density
    if (total_video_comments + total_image_comments) == 0
      return 0
    else
      vd = (total_views*1.0 / (total_video_comments + total_image_comments)).round(4)
      if vd >= 10
        10
      else
        vd.round
      end
    end
  end

  #Sanity check if user is permited to claim Bounties based on his rejection history
  def can_claim_bounties?
    time_out = 1.0 #days
    rejection_rate = 0.5

    if can_claim_bounty == false and (Time.now - latest_rejection_time)/(60*60*24) < time_out
      return false
    else
      total_rejections = BountyClaimRejectionTracker.where("user_id = ? AND active = true AND created_at <= ? AND created_at >= ?", id,  Time.now, (Time.now - 7.days)).count
      total_bounty_claims = BountyClaim.where("user_id = ? AND created_at <= ? AND created_at >= ?", id, Time.now, (Time.now - 7.days)).count

      if total_bounty_claims >= 20 && (total_rejections.to_f / total_bounty_claims.to_f) > rejection_rate
        self.can_claim_bounty = false
        BountyClaimRejectionTracker.where("user_id = ? AND active = true AND created_at <= ? AND created_at >= ?", Time.now, (Time.now - 7.days)).update_all(active: false)
      else
        self.can_claim_bounty = true
      end

      save
      return self.can_claim_bounty

    end
  end

  def list_of_places_mapped
    Venue.where("id IN (?)", VenueComment.where("user_id = #{self.id}").uniq.pluck(:venue_id)).order("Name ASC")
  end

  def venue_comments_from_venue(venue_id)
    VenueComment.where("user_id = #{self.id} AND venue_id = #{venue_id}").order("Id DESC")
  end

  def last_three_comments
    VenueComment.where("user_id = #{self.id} AND media_type != 'text'").order("Id DESC limit 3")
  end

  def last_media_comment
    VenueComment.where("user_id = #{self.id} AND media_type != 'text'").order("Id DESC limit 1")
  end

  #Returns 10 random users out of the top 20 most frequent venue comment posters
  def top_posting_users
    top_20_users = User.where("id != #{self.id}").order("lumens DESC limit 20")
    top_10_random_users = top_20_users.sample(10)
  end


  private ##################################################################################################

  def generate_confirmation_token_for_venue_manager
    if role_id_changed?
      if role.try(:name) == "Venue Manager"
        self.confirmation_token = SecureRandom.hex
      end    
    end
  end

  def notify_venue_managers
    if role_id_changed?
      if role.try(:name) == "Venue Manager"
        Mailer.delay.welcome_venue_manager(self)
      end    
    end
  end

  def ensure_authentication_token
    unless self.authentication_token.present?
      begin
        self.authentication_token = SecureRandom.hex
      end while self.class.exists?(authentication_token: authentication_token)
    end
  end

end
