# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :lytit_constant, :class => 'LytitConstants' do
    constant_name "MyString"
    constant_value 1.5
  end
end
