# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :menu_section_item do
    price 1.5
    menu_section nil
    description "MyText"
  end
end
