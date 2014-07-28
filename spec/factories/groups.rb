# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :group do
    name "MyString"
    description "MyString"
    can_link_events 
    can_link_venues 
    is_public false
    password "MyString"
  end
end
