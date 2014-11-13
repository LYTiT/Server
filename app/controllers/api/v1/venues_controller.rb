class Api::V1::VenuesController < ApiBaseController

  skip_before_filter :set_user, only: [:search, :index]

=begin
  def index
    @venues = Venue.fetch_venues('rankby', '', params[:lat], params[:lng], nil, nil, nil, params[:group_id])
  end
=end

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
    update = false
    @comment = VenueComment.new(venue_comment_params)
    @comment.venue = venue
    @comment.user = @user
    @comment.username_private = @user.username_private

    #To prevent posting pieces being pulled into the following feed we make part i posted invisibly
    if @comment.venue_id == 14002
      @comment.username_private = true
    end

    last_post = @user.venue_comments.order('id ASC').to_a.pop

    if last_post.venue_id == 14002
      update = true
      last_post.comment = @comment.comment
      last_post.venue_id = @comment.venue_id
      last_post.username_private = @comment.username_private
      @comment = last_post
      #last_post.delete
    end

    if not @comment.save
      render json: { error: { code: ERROR_UNPROCESSABLE, messages: @comment.errors.full_messages } }, status: :unprocessable_entity
    else 
      if (@comment.media_type == 'text' and @comment.consider? == 1) and update == false
        @user.update_lumens_after_text(@comment.id)
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
    if @venue
      render json: @venue.groups
    else
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue not found"] } }, :status => :not_found
    end
  end

=begin >>>SEARCHING 1.0<<<
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
      @venues = Venue.fetch_venues('search', params[:q], params[:latitude], params[:longitude], params[:radius], params[:timewalk_start_time], params[:timewalk_end_time], params[:group_id], @user)
      if params[:timewalk_start_time].present? and params[:timewalk_end_time].present?
        render 'timewalk.json.jbuilder'
      else
        render 'search.json.jbuilder'
      end
    end
  end
=end

  def refresh_map_view
    @user = User.find_by_authentication_token(params[:auth_token])
    @venues = Venue.venues_in_view(params[:radius], params[:latitude], params[:longitude])
    render 'display.json.jbuilder'
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
    venue0 = Venue.newfetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude])

    venue1 = Venue.newfetch(params[:name1], params[:formatted_address1], params[:city1], params[:state1], params[:country1], params[:postal_code1], params[:phone_number1], params[:latitude1], params[:longitude1])
    venue2 = Venue.newfetch(params[:name2], params[:formatted_address2], params[:city2], params[:state2], params[:country2], params[:postal_code2], params[:phone_number2], params[:latitude2], params[:longitude2])
    venue3 = Venue.newfetch(params[:name3], params[:formatted_address3], params[:city3], params[:state3], params[:country3], params[:postal_code3], params[:phone_number3], params[:latitude3], params[:longitude3])
    venue4 = Venue.newfetch(params[:name4], params[:formatted_address4], params[:city4], params[:state4], params[:country4], params[:postal_code4], params[:phone_number4], params[:latitude4], params[:longitude4])
    venue5 = Venue.newfetch(params[:name5], params[:formatted_address5], params[:city5], params[:state5], params[:country5], params[:postal_code5], params[:phone_number5], params[:latitude5], params[:longitude5])
    venue6 = Venue.newfetch(params[:name6], params[:formatted_address6], params[:city6], params[:state6], params[:country6], params[:postal_code6], params[:phone_number6], params[:latitude6], params[:longitude6])
    venue7 = Venue.newfetch(params[:name7], params[:formatted_address7], params[:city7], params[:state7], params[:country7], params[:postal_code7], params[:phone_number7], params[:latitude7], params[:longitude7])
    venue8 = Venue.newfetch(params[:name8], params[:formatted_address8], params[:city8], params[:state8], params[:country8], params[:postal_code8], params[:phone_number8], params[:latitude8], params[:longitude8])
    venue9 = Venue.newfetch(params[:name9], params[:formatted_address9], params[:city9], params[:state9], params[:country9], params[:postal_code9], params[:phone_number9], params[:latitude9], params[:longitude9])
    venue10 = Venue.newfetch(params[:name10], params[:formatted_address10], params[:city10], params[:state10], params[:country10], params[:postal_code10], params[:phone_number10], params[:latitude10], params[:longitude10])

    @venues = [venue0, venue1, venue2, venue3, venue4, venue5, venue6, venue7, venue8, venue9, venue10].compact
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
        sphere = venue.city.delete(" ")+(venue.latitude.floor.abs).to_s+(venue.longitude.floor.abs).to_s
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
    params.permit(:comment, :media_type, :media_url)
  end
end
