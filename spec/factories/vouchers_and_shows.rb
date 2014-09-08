FactoryGirl.define do

  factory :showdate do
    ignore do
      date { 1.day.from_now.change(:hour => 20, :min => 0) } # tomorrow at 8p
    end
    date = 1.day.from_now
    thedate { date }
    association :show, :including => date
    end_advance_sales { thedate - 1.minute }
  end

  factory :show do
    ignore do
      including Time.now
    end
    house_capacity 100
    name 'Show'
    opening_date { including - 1.week }
    closing_date { including + 1.week }
  end

  factory :revenue_vouchertype, :class => Vouchertype do
    name 'Revenue vouchertype'
    fulfillment_needed false
    category 'revenue'
    account_code AccountCode.default_account_code
    price 10.00
    season Time.now.year
  end

  factory :revenue_voucher, :class => Voucher do
    sold_on { Time.now }
    showdate
    association :vouchertype, :factory => :revenue_vouchertype
  end

end
