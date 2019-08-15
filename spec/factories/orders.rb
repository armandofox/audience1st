FactoryBot.define do

  factory :order do
    transient do
      vouchers_count 0
      contains_donation false
    end
    association :purchaser, :factory => :customer
    association :processed_by, :factory => :customer
    association :customer
    walkup nil
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

    factory :completed_order do
      sold_on { Time.current }
    end
    
  end

end
