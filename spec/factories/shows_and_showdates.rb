FactoryBot.define do

  factory :showdate do
    transient do
      date { 1.day.from_now.change(:hour => 20, :min => 0) } # tomorrow at 8p
      show_name "Show"
    end
    thedate { date }
    show { create(:show, :name => show_name, :including => date) }
    max_sales { [100, show.house_capacity].min }
    end_advance_sales { thedate - 1.minute }
  end

  factory :show do
    transient do
      including { Time.current }
    end
    house_capacity 200
    sequence(:name) { |n| "Show #{n}" }
    opening_date { including - 1.week }
    closing_date { opening_date + 1.month }
    listing_date { Time.current }
  end

end
