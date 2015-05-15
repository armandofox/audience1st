FactoryGirl.define do

  factory :donation do
    amount 25
    account_code { Donation.default_code }
  end

end
