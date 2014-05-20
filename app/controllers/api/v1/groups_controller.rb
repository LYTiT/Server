class Api::V1::GroupsController < ApiBaseController

  def create
    @group = Group.new(group_params)

    if @group.save
      # add user creating group as admin
      GroupsUser.create(group_id: @group.id, user_id: @user.id, is_admin: true)
      render json: @group
    else
      render json: @group.errors, status: :unprocessable_entity
    end
  end

  def update
    @group = Group.find(params[:id])
    permitted_params = group_params

    if @group.update_attributes(permitted_params)
      render json: @group
    else
      render json: @group.errors, status: :unprocessable_entity
    end
  end

  def join
    @group = Group.find(params[:group_id])
    status, message = @group.join(@user.id, params[:password])

    if status
      render json: { joined: true }, status: :ok
    else
      render json: { joined: false, errors: [message] }, status: :unauthorized
    end
  end

  def leave
    @group = Group.find(params[:group_id])
    @group.remove(@user.id)
    render json: { left: true }, status: :ok
  end

  def search
    @groups = Group.where("LOWER(name) like ?", params[:q].to_s.downcase + '%')
  end

  def users
    @group = Group.find_by_id(params[:group_id])

    if not @group
      render json: { errors: ["Group with id #{params[:group_id]} not found"] }, status: :not_found
    end
  end

  def venues
    @group = Group.find_by_id(params[:group_id])
    if @group
      render json: @group.venues_with_user_who_added
    else
      render json: { errors: ["Group with id #{params[:group_id]} not found"] }, status: :not_found
    end
  end

  def delete
    @group = Group.find_by_id(params[:group_id])
    if @group
      @group.destroy
      render json: { deleted: true }, status: :ok
    else
      render json: { deleted: false, errors: ["Group with id #{params[:group_id]} not found"] }, status: :not_found
    end
  end

  def toggle_admin
    @group = Group.find(params[:group_id])
    if @group.is_user_admin?(@user.id)
      @group.toggle_user_admin(params[:user_id], params[:approval])
      render json: { success: true }
    else
      render json: { errors: ['You dont have admin privileges for this group'] }
    end
  end

  def remove_user
    @group = Group.find(params[:group_id])
    if @group.is_user_admin?(@user.id)
      @group.remove(params[:user_id])
      render json: { success: true }
    else
      render json: { errors: ['You dont have admin privileges for this group'] }
    end
  end

  def add_venue
    @group = Group.find(params[:group_id])
    @venue = Venue.find(params[:venue_id])
    status, message = @group.add_venue(@venue.id, @user.id)
    if status
      render json: { success: true }
    else
      render json: { errors: [message] }
    end
  end

  def remove_venue
    @group = Group.find(params[:group_id])
    @venue = Venue.find(params[:venue_id])
    status, message = @group.remove_venue(@venue.id, @user.id)
    if status
      render json: { success: true }
    else
      render json: { errors: [message] }
    end
  end

  private

  def group_params
    params.require(:group).permit(:name, :description, :is_public, :password)
  end
end
