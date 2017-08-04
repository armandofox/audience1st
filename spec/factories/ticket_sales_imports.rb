FactoryGirl.define do

  factory :ticket_sales_import do
    association :show
    association :showdate
    association :customer
    type 'TicketSalesImport'
    
  end

end
