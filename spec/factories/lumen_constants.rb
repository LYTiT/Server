# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :lumen_constant, :class => 'LumenConstants' do
    constant_name "MyString"
    constant_value 1.5
  end
end
