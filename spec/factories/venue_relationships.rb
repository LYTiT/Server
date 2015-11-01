# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :venue_relationship do
    ufollower_id 1
    vfollowed_id 1
  end
end
