FactoryBot.define do

  factory :donation do
    amount 25
    account_code { Donation.default_code }
  end

  factory :account_code do
    sequence(:code)  { |n| Kernel.sprintf("%04d", n) }
    name { "Account #" + code }
  end

end
