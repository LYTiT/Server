# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :venue_comment do
    comment "MyString"
    media_type "MyString"
    media_url "MyString"
    user nil
    venue nil
  end
end
