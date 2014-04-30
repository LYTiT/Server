class Api::V1::GroupsController < ApiBaseController
  
  skip_before_filter :set_user, only: [:search]
  
  def create
    @group = Group.new(group_params)

    if @group.save
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
    render json: @groups
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
  
  private

  def group_params
    params.require(:group).permit(:name, :description, :is_public, :password, :user_id, :venue_id)
  end
end
