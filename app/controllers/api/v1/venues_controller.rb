class Api::V1::VenuesController < ApiBaseController

  skip_before_filter :set_user, only: [:search, :index]

  def show
    @venue = Venue.find(params[:id])
    #@venue.populate_google_address
    venue = @venue.as_json(include: :venue_messages)
    venue[:menu] = @venue.menu_sections.as_json(
      only: [:id, :name], 
      include: {
        :menu_section_items => {
          only: [:id, :name, :price, :description]
        }
      }
    )
    render json: venue
  end

  def add_comment
    parts_linked = false #becomes 'true' when Venue Comment is formed by two parts conjoining
    assign_lumens = false #in v3.0.0 posting by parts makes sure that lumens are not assigned for the creation of the text part of a media Venue Comment

    session = params[:session]
    incoming_part_type = venue.id == 14002 ? "media" : "text" #we use the venue_id '14002' as a key to signal a posting by parts operation

    completion = false #add_comment method is completed either once a Venue Comment or a Temp Posting Housing object is created
    
    if session != nil #posting by parts algorithm for versions >= 3.1.0 have session ids assigned to all Venue Comments and their parts

      if session != 0 #simple text comments have a session id = 0 and do not need to be seperated into parts
        posting_parts = @user.temp_posting_housings.order('id ASC')

        if posting_parts.count == 0 #if no parts are housed there is nothing to link
          vc_part = TempPostingHousing.new(:user_id => @user.id, :venue_id => venue.id, :media_type => params[:media_type], :media_url => params[:media_url], 
                                        :session => session, :username_private => @user.username_private)
          vc_part.save
          completion = true
          render json: { success: true }
        else
          for part in posting_parts #iterate through posting parts to find matching part (equivalen session id) of incoming Venue Comment part

            if part.session != nil and part.session == session
              @comment = VenueComment.new(venue_comment_params)
              @comment.user = @user
              @comment.venue = venue
              @comment.username_private = @user.username_private
              if incoming_part_type == "media" #pull venue, comment and visability data as the incoming part is the media
                @comment.venue = part.venue
                @comment.comment = part.comment
                @comment.username_private = part.username_private
              else #pull media data as the incoming part is the text
                @comment.media_type = part.media_type
                @comment.media_url = part.media_url
              end
              part.delete
              parts_linked = true
              break  
            else #if a part has been housed for over a reasonable period of time we can assume that it is no longer needed.
              if (((Time.now - part.created_at) / 1.minute) >= 30.0)
                part.delete
              end
            end

          end

          if parts_linked == false #appropraite part has not arrived yet so we store the current part in temp housing
            vc_part = TempPostingHousing.new(:user_id => @user.id, :venue_id => venue.id, :media_type => params[:media_type], :media_url => params[:media_url], 
                                          :session => session, :username_private => @user.username_private)          
            vc_part.save
            completion = true
            render json: { success: true }
          end
        end

      else #dealing with a simple text comment
        assign_lumens = true
        @comment = VenueComment.new(venue_comment_params)
        @comment.venue = venue
        @comment.user = @user
        @comment.username_private = @user.username_private
      end


#V3.0.0 Posting by Parts for Backward Compatability >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    else 
      @comment = VenueComment.new(venue_comment_params)
      @comment.venue = venue
      @comment.user = @user
      @comment.username_private = @user.username_private
      if @user.venue_comments.count > 0
        last_post = @user.venue_comments.order('id ASC').to_a.pop
      end
      #To prevent posting pieces being pulled into the following feed we make part i posted invisibly. 
      #This is a temp solution to handle the instance of the text uploading before the media (occurs under poor service conditions).
      #Note: this is flawed!
      if @comment.venue_id == 14002
        @comment.username_private = true
        if last_post != nil
          if ((Time.now - last_post.created_at) / 1.minute).abs <= 1 && last_post.media_type == 'text'
            if last_post.venue_id == 14002 && last_post.comment == 'temp'
              last_post.venue_id = last_post.views
              last_post.views = 0
              last_post.comment = nil
              last_post.media_type = @comment.media_type
              last_post.media_url = @comment.media_url
              last_post.lumen_values.to_a.pop.delete #deleting lumen values for text since it's not a standalone text comment.
              @comment = last_post

            else
              last_post.media_type = @comment.media_type
              last_post.media_url = @comment.media_url
              last_post.lumen_values.to_a.pop.delete #deleting lumen values for text since it's not a standalone text comment.
              @comment = last_post

              @user.adjust_lumens #removing text lumens since posting is not a text
            end
          end
        end
      else #regular text comment not part of posting by parts thus should receive lumens
        assign_lumens = true
      end

      #Regular posting by parts, text is uploaded after media part.
      if last_post != nil and last_post.venue_id == 14002
        if not last_post.media_url.blank?
          last_post.comment = @comment.comment
          last_post.venue_id = @comment.venue_id
          last_post.username_private = @comment.username_private
          @comment = last_post
          #last_post.delete
        end
      end
      #Handles the case when blank text is uploaded before media part of comment.
      if @comment.comment.blank? && @comment.media_url.blank?
        @comment.views = @comment.venue_id
        @comment.venue_id = 14002
        @comment.comment = "temp"
      end
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    end


    if completion == false #a Venue Comment has been created instead of a Temp Posting Housing object so now it needs to be saved

      if not @comment.save
        render json: { error: { code: ERROR_UNPROCESSABLE, messages: @comment.errors.full_messages } }, status: :unprocessable_entity
      else 
        if (@comment.media_type == 'text' and @comment.consider? == 1) and assign_lumens == true
          @user.update_lumens_after_text(@comment.id)
        end

        #check to see if there is @Group link present in text (introduced in v3.2.0)
        if @user.version_compatible?("3.2.0")
          if params[:at_ids] != nil
            for gid in params[:at_ids]
              receiving_group = Group.find_by_id(gid["group_id"])
              if receiving_group.is_user_member?(@user.id)
                receiving_group.at_group!(@comment)
              end
            end
          else
            for gname in params[:at_names]
              receiving_group = Group.find_by_name(gname["group_name"])
              if receiving_group.is_user_member?(@user.id)
                receiving_group.at_group!(@comment)
              end
            end
          end
        end

      end

    end
  end

  def delete_comment
    VenueComment.where(user_id: @user.id, id: params[:id]).destroy_all
    render json: { success: true }
  end

  def report_comment
    venue_comment = VenueComment.find(params[:comment_id])
    fc = FlaggedComment.new
    fc.user_id = @user.id
    fc.message = params[:message]
    fc.venue_comment_id = venue_comment.id
    fc.save
    render json: fc
  end

  def get_comments
    @venue = Venue.find_by_id(params[:venue_id])
    if not @venue
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue not found"] } }, :status => :not_found
    else
      @comments = @venue.visible_venue_comments.page(params[:page]).per(5).order("created_at desc")
    end
  end

  def mark_comment_as_viewed
    @comment = VenueComment.find_by_id_and_venue_id(params[:post_id], params[:venue_id])

    #consider is used for Lumen calculation. Initially it is set to 2 for comments with no views and then is
    #updated to the true value (1 or 0) for a particular comment after a view (comments with no views aren't considered
    #for Lumen calcuation by default)

    if (@comment.is_viewed?(@user) == false) #and (@comment.user_id != @user.id)
      poster_id = @comment.user_id
      poster = User.find_by(id: poster_id)
      poster.update_total_views
      @comment.update_views
      @comment.save
      if poster_id != @user.id
        @comment.calculate_adj_view
        @comment.save
        if @comment.consider? == 1 
          poster.update_lumens_after_view(@comment)
        end
      end
    end

    if @comment.present?
        comment_view = CommentView.new
        comment_view.user = @user
        comment_view.venue_comment = @comment
        comment_view.save
    else
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue / Post not found"] } }, :status => :not_found
      return
    end
  end


  def get_groups
    @venue = Venue.find_by_id(params[:venue_id])
    if not @venue
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue not found"] } }, :status => :not_found
    end
  end

  def refresh_map_view
    @user = User.find_by_authentication_token(params[:auth_token])
    @venues = Venue.venues_in_view(params[:radius], params[:latitude], params[:longitude])
    render 'display.json.jbuilder'
  end

  #Top viewed comments of a geographical area based on zoom level. Note how we must account for different timezones since all dates are stored in UTC.
  def get_geo_spotlyt
    Timezone::Configure.begin do |c|
      c.username = 'lytit'
    end
    selected_date = params[:spotlyt_date]
    selection = Date.parse(selected_date)

    @user = User.find_by_authentication_token(params[:auth_token])
    @venues = Venue.venues_in_view(params[:radius], params[:latitude], params[:longitude])

    min_long = params[:longitude].to_f - params[:radius].to_i / (113.2 * 1000 * Math.cos(params[:latitude].to_f * Math::PI / 180))
    max_long = params[:longitude].to_f + params[:radius].to_i / (113.2 * 1000 * Math.cos(params[:latitude].to_f * Math::PI / 180))
    lat_coverage = (max_long-min_long).abs
    rep_timezone = Timezone::Zone.new :latlon => [@venues[0].latitude, @venues[0].longitude]

    comments = []
    for venue in @venues
      #requesting spotlyt of a larger area which may contain multiple timezones thus must check each venue's timezone individually.  
      if lat_coverage >= 15.0 
        timezone = Timezone::Zone.new :latlon => [venue.latitude, venue.longitude]
        
      #requesting spotlyt of a small area which is in one timezone thus no need to pull the timezone for each venue individually.
      else
        timezone = rep_timezone
      end

      start_t = selection + (selection - selection.in_time_zone(timezone.active_support_time_zone)).seconds
      end_t = (selection + 24.hour) + ((selection + 24.hour) - (selection + 24.hour).in_time_zone(timezone.active_support_time_zone)).seconds
      comments << VenueComment.where("media_type = 'image' AND created_at <= ? AND created_at >= ? AND venue_id = #{venue.id}", end_t, start_t)
      comments << VenueComment.where("media_type = 'video' AND created_at <= ? AND created_at >= ? AND venue_id = #{venue.id}", end_t, start_t)
    end
    sorted_comments = comment.sort_by {|entry| entry.views}
    @spotlyts = sorted_comments.reverse.first(10)
  end

  def search
    @user = User.find_by_authentication_token(params[:auth_token])
    if params[:group_id].present? and not params[:q].present?
      @group = Group.find_by_id(params[:group_id])
      if @group
        render json: @group.venues_with_user_who_added
      else
        render json: { error: { code: ERROR_NOT_FOUND, messages: ["Group with id #{params[:group_id]} not found"] } }, status: :not_found
      end
    else

      #I am aware this approach is Muppet, need to update later 
      venue0 = Venue.newfetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude], params[:pin_drop])

      venue1 = Venue.newfetch(params[:name1], params[:formatted_address1], params[:city1], params[:state1], params[:country1], params[:postal_code1], params[:phone_number1], params[:latitude1], params[:longitude1], params[:pin_drop])
      venue2 = Venue.newfetch(params[:name2], params[:formatted_address2], params[:city2], params[:state2], params[:country2], params[:postal_code2], params[:phone_number2], params[:latitude2], params[:longitude2], params[:pin_drop])
      venue3 = Venue.newfetch(params[:name3], params[:formatted_address3], params[:city3], params[:state3], params[:country3], params[:postal_code3], params[:phone_number3], params[:latitude3], params[:longitude3], params[:pin_drop])
      venue4 = Venue.newfetch(params[:name4], params[:formatted_address4], params[:city4], params[:state4], params[:country4], params[:postal_code4], params[:phone_number4], params[:latitude4], params[:longitude4], params[:pin_drop])
      venue5 = Venue.newfetch(params[:name5], params[:formatted_address5], params[:city5], params[:state5], params[:country5], params[:postal_code5], params[:phone_number5], params[:latitude5], params[:longitude5], params[:pin_drop])
      venue6 = Venue.newfetch(params[:name6], params[:formatted_address6], params[:city6], params[:state6], params[:country6], params[:postal_code6], params[:phone_number6], params[:latitude6], params[:longitude6], params[:pin_drop])
      venue7 = Venue.newfetch(params[:name7], params[:formatted_address7], params[:city7], params[:state7], params[:country7], params[:postal_code7], params[:phone_number7], params[:latitude7], params[:longitude7], params[:pin_drop])
      venue8 = Venue.newfetch(params[:name8], params[:formatted_address8], params[:city8], params[:state8], params[:country8], params[:postal_code8], params[:phone_number8], params[:latitude8], params[:longitude8], params[:pin_drop])
      venue9 = Venue.newfetch(params[:name9], params[:formatted_address9], params[:city9], params[:state9], params[:country9], params[:postal_code9], params[:phone_number9], params[:latitude9], params[:longitude9], params[:pin_drop])
      venue10 = Venue.newfetch(params[:name10], params[:formatted_address10], params[:city10], params[:state10], params[:country10], params[:postal_code10], params[:phone_number10], params[:latitude10], params[:longitude10], params[:pin_drop])

      @venues = [venue0, venue1, venue2, venue3, venue4, venue5, venue6, venue7, venue8, venue9, venue10].compact

      #@venues = Venue.fetch_venues('search', params[:q], params[:latitude], params[:longitude], params[:radius], params[:timewalk_start_time], params[:timewalk_end_time], params[:group_id], @user)
      render 'search.json.jbuilder'
    end
  end
  
  def search_to_follow
    @user = User.find_by_authentication_token(params[:auth_token])

    #I am aware this approach is Muppet, need to update later 
    venue0 = Venue.newfetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude], params[:pin_drop])

    venue1 = Venue.newfetch(params[:name1], params[:formatted_address1], params[:city1], params[:state1], params[:country1], params[:postal_code1], params[:phone_number1], params[:latitude1], params[:longitude1], params[:pin_drop])
    venue2 = Venue.newfetch(params[:name2], params[:formatted_address2], params[:city2], params[:state2], params[:country2], params[:postal_code2], params[:phone_number2], params[:latitude2], params[:longitude2], params[:pin_drop])
    venue3 = Venue.newfetch(params[:name3], params[:formatted_address3], params[:city3], params[:state3], params[:country3], params[:postal_code3], params[:phone_number3], params[:latitude3], params[:longitude3], params[:pin_drop])
    venue4 = Venue.newfetch(params[:name4], params[:formatted_address4], params[:city4], params[:state4], params[:country4], params[:postal_code4], params[:phone_number4], params[:latitude4], params[:longitude4], params[:pin_drop])
    venue5 = Venue.newfetch(params[:name5], params[:formatted_address5], params[:city5], params[:state5], params[:country5], params[:postal_code5], params[:phone_number5], params[:latitude5], params[:longitude5], params[:pin_drop])
    venue6 = Venue.newfetch(params[:name6], params[:formatted_address6], params[:city6], params[:state6], params[:country6], params[:postal_code6], params[:phone_number6], params[:latitude6], params[:longitude6], params[:pin_drop])
    venue7 = Venue.newfetch(params[:name7], params[:formatted_address7], params[:city7], params[:state7], params[:country7], params[:postal_code7], params[:phone_number7], params[:latitude7], params[:longitude7], params[:pin_drop])
    venue8 = Venue.newfetch(params[:name8], params[:formatted_address8], params[:city8], params[:state8], params[:country8], params[:postal_code8], params[:phone_number8], params[:latitude8], params[:longitude8], params[:pin_drop])
    venue9 = Venue.newfetch(params[:name9], params[:formatted_address9], params[:city9], params[:state9], params[:country9], params[:postal_code9], params[:phone_number9], params[:latitude9], params[:longitude9], params[:pin_drop])
    venue10 = Venue.newfetch(params[:name10], params[:formatted_address10], params[:city10], params[:state10], params[:country10], params[:postal_code10], params[:phone_number10], params[:latitude10], params[:longitude10], params[:pin_drop])

    venues_crude = [venue0, venue1, venue2, venue3, venue4, venue5, venue6, venue7, venue8, venue9, venue10].compact
    @venues = venues_crude.uniq
    render 'search_to_follow.json.jbuilder'
  end  

  def get_suggested_venues
    @user = User.find_by_authentication_token(params[:auth_token])
    @suggestions = Venue.near_locations(params[:latitude], params[:longitude])
    render 'get_suggested_venues.json.jbuilder'
  end

  def get_recommendations
    @user = User.find_by_authentication_token(params[:auth_token])
    @recommendations = Venue.recommended_venues(@user, params[:latitude], params[:longitude])
    render 'get_recommendations.json.jbuilder'
  end

  def rate_venue
    venue = Venue.find(params[:venue_id])
    @venue_rating = VenueRating.new(params.permit(:rating))
    @venue_rating.venue = venue
    @venue_rating.user = @user

    if @venue_rating.save
      render json: venue
    else
      render json: { error: { code: ERROR_UNPROCESSABLE, messages: @venue_rating.errors.full_messages } }, status: :unprocessable_entity
    end
  end

  def vote
    vote_value = params[:rating] > LytitBar.instance.position ? 1 : -1

    venue = Venue.find(params[:venue_id])
    rating = venue.rating
    v = LytitVote.new(:value => vote_value, :venue_id => params[:venue_id], :user_id => @user.id, :venue_rating => rating ? rating : 0, 
                      :prime => venue.get_k, :raw_value => params[:rating])

    if v.save
      venue.delay.account_new_vote(vote_value, v.id)
      @user.update_lumens_after_vote(v.id)

      if LytSphere.where("venue_id = ?", params[:venue_id]).count == 0
        sphere = venue.city.delete(" ")+(venue.latitude.round(0).abs).to_s+(venue.longitude.round(0).abs).to_s
        lyt_sphere = LytSphere.new(:venue_id => venue.id, :sphere => sphere)
        lyt_sphere.save
      end

      render json: {"registered_vote" => vote_value, "venue_id" => params[:venue_id]}, status: :ok
    else
      render json: { error: { code: ERROR_UNPROCESSABLE, messages: v.errors.full_messages } }, status: :unprocessable_entity
    end
  end

  def followers
    @venue = Venue.find(params[:venue_id])
    @followers = @venue.followers
  end


  private

  def venue
    @venue ||= Venue.find(params[:venue_id])
  end

  def venue_comment_params
    params.permit(:comment, :media_type, :media_url, :session)
  end
end
