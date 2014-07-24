# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :group do
    name "MyString"
    description "MyString"
    can_link_events true
    can_link_venues true
    is_public false
    password "MyString"
  end
end
