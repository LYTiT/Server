class MenuSectionItem < ActiveRecord::Base

  belongs_to :menu_section, :inverse_of => :menu_section_items

  validates :name, presence: true
  validates :position, numericality: { only_integer: true }, allow_nil: true

  default_scope { order('position ASC, id ASC') }

end
