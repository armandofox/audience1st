FactoryBot.define do

  factory :label do
    sequence(:name) { |n| "Label-#{n}" }
  end

end
