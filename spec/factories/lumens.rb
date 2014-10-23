# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :lumen, :class => 'Lumens' do
    value 1.5
    user 1
  end
end
