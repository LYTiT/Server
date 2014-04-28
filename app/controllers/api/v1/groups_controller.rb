class Api::V1::GroupsController < ApiBaseController

  def create
    @group = Group.new(group_params)

    if @group.save
      render json: @group
    else
      render json: @group.errors, status: :unprocessable_entity
    end
  end

  private

  def group_params
    params.require(:group).permit(:name, :description, :is_public, :password, :user_id)
  end
end
