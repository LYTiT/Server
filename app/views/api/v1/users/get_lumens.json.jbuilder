json.lumen_value @user.lumens
json.gross_lumen_value @user.monthly_gross_lumens

json.video_count @user.total_video_comments
json.photo_count @user.total_image_comments
json.text_count @user.total_text_comments
json.bonus_count @user.total_bonuses
json.view_count @user.total_views
json.bounty_count @user.total_bounties
json.mapped_places_count @user.mapped_places_count

json.video_lumens @user.video_lumens
json.photo_lumens @user.image_lumens
json.text_lumens @user.text_lumens
json.bonus_lumens @user.bonus_lumens
json.bounty_lumens @user.bounty_lumens

json.view_rank @user.lumen_views_contribution_rank
json.video_rank @user.lumen_video_contribution_rank
json.photo_rank @user.lumen_image_contribution_rank
json.text_rank @user.lumen_text_contribution_rank
json.bonus_rank @user.lumen_bonus_contribution_rank
json.bounty_rank @user.lumen_bounty_contribution_rank

json.view_density @user.view_density

json.video_radius @user.video_radius
json.image_radius @user.image_radius
json.text_radius @user.text_radius
json.bonus_radius @user.bonus_radius
json.view_radius @user.views_radius
json.bounty_radius @user.bounty_radius
json.mapped_places_radius @user.mapped_places_radius
