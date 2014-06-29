class MenuSectionItem < ActiveRecord::Base

  belongs_to :menu_section, :inverse_of => :menu_section_items

  validates :name, presence: true

end
