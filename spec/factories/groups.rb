# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :group do
    name "MyString"
    description "MyString"
    can_link_event false #can link event
    is_public false
    password "MyString"
  end
end
