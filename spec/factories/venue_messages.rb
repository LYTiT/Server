# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :venue_message do
    message "MyString"
    venue nil
    position 1
  end
end
