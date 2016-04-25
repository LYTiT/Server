class ListCategoryEntry < ActiveRecord::Base
  belongs_to :feed
  belongs_to :list_category
  
end