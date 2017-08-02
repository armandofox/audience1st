FactoryGirl.define do

  factory :ticket_sales_import do
    association :show
    association :showdate
    association :customer

    factory :brown_paper_tickets_import do
    end

  end

end
