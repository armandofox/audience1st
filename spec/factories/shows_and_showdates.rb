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
    closing_date { opening_date + 1.month }
    listing_date { Time.now }
  end


end
