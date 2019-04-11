FactoryBot.define do

  factory :valid_voucher do
    transient do
      price 7
    end
    start_sales { 1.hour.ago.rounded_to(:minute) }
    end_sales   { 10.minutes.from_now.rounded_to(:minute) }
    max_sales_for_type 100
    association :showdate
    association :vouchertype, :factory => :revenue_vouchertype
  end

  factory :vouchertype do
    account_code { AccountCode.default_account_code }
    season Time.current.year
    fulfillment_needed false
    changeable true

    factory :revenue_vouchertype do
      name 'Revenue vouchertype'
      offer_public Vouchertype::ANYONE
      category 'revenue'
      price 12
    end

    factory :comp_vouchertype do
      name 'Free'
      category 'comp'
      price 0
      offer_public Vouchertype::BOXOFFICE
    end      

    factory :vouchertype_included_in_bundle do
      offer_public Vouchertype::BOXOFFICE
      name 'Subscriber voucher'
      category 'subscriber'
      price 0
    end

    factory :nonticket_vouchertype do
      offer_public Vouchertype::ANYONE
      name 'nonticket product'
      category 'nonticket'
      price 10
    end

    factory :bundle do
      transient do
        including { Hash.new }
      end
      name 'Bundle'
      category 'bundle'
      price 50
      offer_public Vouchertype::ANYONE
      subscription false
      included_vouchers { Hash.new }
      after(:build) do |vt,evaluator|
        evaluator.including.each_pair do |vtype, count|
          vt.included_vouchers[vtype.id] = count
        end
      end
    end

  end

  factory :voucher do
    customer      

    factory :revenue_voucher do
      association :vouchertype, :factory => :revenue_vouchertype
      amount { vouchertype.price }
      category { vouchertype.category }
      account_code { vouchertype.account_code }
      
      factory :walkup_voucher do
        walkup true
        customer { Customer.walkup_customer }
      end
    end

    factory :subscriber_voucher do
      transient do
        season { Time.this_season }
      end
      association :vouchertype, :factory => :vouchertype_included_in_bundle
      amount 0
      category 'subscriber'
    end

    factory :bundle_voucher do
      transient do
        including Hash.new
        subscription false
        season { Time.this_season }
      end
      vouchertype do
        included_vouchertypes = {}
        including.each_pair do |voucher,count|
          included_vouchertypes[voucher.vouchertype] = count
        end
        create(:bundle, :subscription => subscription, :season => season, :including => included_vouchertypes)
      end
      amount 50
      account_code { vouchertype.account_code }
      category 'bundle'
    end
  end
end
