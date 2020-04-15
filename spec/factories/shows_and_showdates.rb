FactoryBot.define do

  factory :showdate do
    transient do
      date { 1.day.from_now.change(:hour => 20, :min => 0) } # tomorrow at 8p
      show_name "Show"
    end
    house_capacity 200
    thedate { date }
    show { create(:show, :name => show_name, :including => date) }
    max_advance_sales { [100, house_capacity].min }
    end_advance_sales { thedate - 1.minute }

    factory :reserved_seating_showdate do
      seatmap { create(:seatmap) }
    end

    factory :live_stream_showdate do
      live_stream true
      house_capacity ValidVoucher::INFINITE
    end
    factory :stream_anytime_showdate do
      stream_anytime true
      house_capacity ValidVoucher::INFINITE
    end
  end

  factory :show do
    transient do
      including { Time.current }
    end
    sequence(:name) { |n| "Show #{n}" }
    opening_date { including - 1.week }
    closing_date { opening_date + 1.month }
    listing_date { Time.current }
  end

  factory :seatmap do
    # default one looks like this:
    #   A1 - A2 -
    #     B1 -  B2     (B1 is an accessible seat)
    sequence(:name) { |n| "Seatmap #{n}" }
    csv "A1,,A2\r\n,B1+,,B2\r\n"
    seat_rows [['A1',nil,'A2',nil],[nil,'B1+',nil,'B2']]
    image_url 'http://foo.com/seatmap.png'
    after(:build) do |s,ev|
      s.parse_rows
    end
  end
end
