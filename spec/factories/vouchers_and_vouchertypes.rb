FactoryGirl.define do

  factory :revenue_vouchertype, :class => Vouchertype do
    name 'Revenue vouchertype'
    fulfillment_needed false
    category 'revenue'
    account_code { AccountCode.default_account_code }
    price 12.00
    season Time.now.year
  end

  factory :revenue_voucher, :class => Voucher do
    showdate
    customer
    association :vouchertype, :factory => :revenue_vouchertype
    amount { vouchertype.price }
    category { vouchertype.category }
  end

end
