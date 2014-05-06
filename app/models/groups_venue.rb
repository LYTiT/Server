class GroupsVenue < ActiveRecord::Base
  
  belongs_to :venue
  belongs_to :group
  
end
