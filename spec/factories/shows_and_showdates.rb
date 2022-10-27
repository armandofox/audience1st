FactoryBot.define do

  factory :show do
    sequence(:name) { |n| "Show #{n}" }
    listing_date { Time.current }
    season { Time.this_season }
  end

  factory :seating_zone do
    sequence(:name) { |n| "Zone#{n}" }
    sequence(:short_name) { |n| "z#{n}" }
  end

  # Seatmap with 4 seats (1 is accessible) all in zone 'res'
  factory :seatmap do
    # default one looks like this:
    #   A1 -   A2  -
    #      B1+  -  B2     (B1 is an accessible seat)
    sequence(:name) { |n| "Seatmap #{n}" }
    image_url 'http://foo.com/seatmap.png'
    csv ",,,,,,,,,,,,,,,,res:A1,,res:A2\r\n,,,,,,,,,,,,,,,,,res:B1+,,res:B2\r\n"
    after(:build) do |s,ev|
      Seatmap::Parser.new(s).parse_csv
    end
  end

  factory :showdate do
    transient do
      date { 1.day.from_now.change(:hour => 20, :min => 0) } # tomorrow at 8p
      show_name "Show"
    end
    show { FactoryBot.create(:show, :name => show_name) }
    house_capacity 200
    thedate { date }
    max_advance_sales { [100, house_capacity].min }
    live_stream false
    stream_anytime false
    
    factory :reserved_seating_showdate do
      transient do
        sm { FactoryBot.create(:seatmap) }
      end
      seatmap { sm }
      max_advance_sales { sm.seat_count }
    end
    
    factory :live_stream_showdate do
      live_stream true
      house_capacity ValidVoucher::INFINITE
      access_instructions 'Instructions here for stream access'
    end
    factory :stream_anytime_showdate do
      stream_anytime true
      house_capacity ValidVoucher::INFINITE
      access_instructions 'Instructions here for stream-on-demand access'
    end
  end

end
