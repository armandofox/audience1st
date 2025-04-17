FactoryBot.define do

  factory :order do
    transient do
      vouchers_count { 0 }
      contains_donation { false }
      purchaser_or_customer { create :customer }
    end

    purchaser { purchaser_or_customer }
    customer  { purchaser_or_customer }

    association :processed_by, :factory => :customer
    walkup { nil }
    purchasemethod { Purchasemethod.get_type_by_name(:box_cash) }

    after(:build) do |order|
      if order.walkup
        order.customer = order.purchaser = Customer.walkup_customer
        order.processed_by ||= Customer.boxoffice_daemon
      end
    end
    after(:create) do |order,evaluator|
      1.upto evaluator.vouchers_count do
        order.items << create(:revenue_voucher, :customer => order.customer)
      end
      if evaluator.contains_donation
        #order.items << create(:donation, :customer => order.customer)
        order.add_donation(create(:donation, :customer => order.customer))
      end
    end

    trait :gift do
      purchaser { create :customer }
    end

    factory :order_from_vouchers do
      sold_on { Time.current }
      transient do
        vouchers { [] }
      end
      after(:create) do |order,evaluator|
        evaluator.vouchers.each do |v|
          order.items << v
        end
      end
    end

    factory :completed_order do
      sold_on { Time.current }
    end
      
  end

end
