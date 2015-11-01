# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :lumen_value, :class => 'LumenValues' do
    value 1.5
  end
end
