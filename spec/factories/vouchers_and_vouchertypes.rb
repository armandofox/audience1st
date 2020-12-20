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
    season { Time.current.year }
    fulfillment_needed false
    changeable true
    
    factory :revenue_vouchertype do
      sequence(:name)  { |n| "Revenue vouchertype #{n}" }
      offer_public Vouchertype::ANYONE
      category 'revenue'
      price 12
    end

    factory :comp_vouchertype do
      sequence(:name) { |n| "Comp #{n}" }
      category 'comp'
      price 0
      offer_public Vouchertype::BOXOFFICE
    end      

    factory :vouchertype_included_in_bundle do
      offer_public Vouchertype::BOXOFFICE
      sequence(:name) { |n| "Subscriber voucher #{n}" }
      category 'subscriber'
      price 0
    end

    factory :nonticket_vouchertype do
      offer_public Vouchertype::ANYONE
      sequence(:name) { |n| "nonticket product #{n}" }
      category 'nonticket'
      price 10
    end

    factory :bundle do
      transient do
        including { Hash.new }
      end
      sequence(:name) { |n| "Bundle #{n}" }
      category 'bundle'
      price 50
      offer_public Vouchertype::ANYONE
      subscription false
      included_vouchers { Hash.new }
      after(:build) do |vt,evaluator|
        evaluator.including.each_pair do |vtype, count|
          vt.included_vouchers[vtype.id.to_s] = count
        end
      end
    end

  end

  factory :voucher do
    customer      
    finalized true
    
    factory :revenue_voucher do
      association :vouchertype, :factory => :revenue_vouchertype
      amount { vouchertype.price }
      account_code { vouchertype.account_code }
      
      factory :walkup_voucher do
        walkup true
        customer { Customer.walkup_customer }
      end

      factory :canceled_revenue_voucher do
        after(:create) do |vch,evaluator|
          vch.cancel!(create(:boxoffice_manager))
        end
      end
    end

    factory :nonticket_item do
      association :vouchertype, :factory => :nonticket_vouchertype
    end

    factory :comp_voucher do
      association :vouchertype, :factory => :revenue_vouchertype
      amount 0
      account_code { vouchertype.account_code }
    end
    
    factory :subscriber_voucher do
      transient do
        season { Time.this_season }
      end
      association :vouchertype, :factory => :vouchertype_included_in_bundle
      amount 0
    end

    factory :bundle_voucher do
      transient do
        including Hash.new
        subscription false
        fulfillment_needed false
        season { Time.this_season }
      end
      vouchertype do
        included_vouchertypes = {}
        including.each_pair do |voucher,count|
          included_vouchertypes[voucher.vouchertype] = count
        end
        create(:bundle, :subscription => subscription, :fulfillment_needed => fulfillment_needed,
          :season => season, :including => included_vouchertypes)
      end
      amount 50
      account_code { vouchertype.account_code }
    end
  end
end
