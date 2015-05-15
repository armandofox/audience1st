FactoryGirl.define do

  factory :order do
    association :purchaser, :factory => :customer
    association :processed_by, :factory => :customer
    customer
    walkup false
    purchasemethod { Purchasemethod.find_by_shortdesc(:box_cash) }

    after_build do |order|
      if walkup
        order.customer = order.purchaser = Customer.walkup_customer
        order.processed_by ||= Customer.boxoffice_daemon
      end
    end

  end

end
