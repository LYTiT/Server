# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :venue do
    name "MyString"
    latitude "MyString"
    longitude "MyString"
    rating 1
    phone_number "MyString"
    address "MyText"
    city "MyString"
    state "MyString"
  end
end
