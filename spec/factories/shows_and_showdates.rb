FactoryBot.define do

  factory :showdate do
    transient do
      date { 1.day.from_now.change(:hour => 20, :min => 0) } # tomorrow at 8p
      show_name "Show"
    end
    thedate { date }
    show { create(:show, :name => show_name, :including => date) }
    max_advance_sales { [100, show.house_capacity].min }
    end_advance_sales { thedate - 1.minute }

    factory :reserved_seating_showdate do
      seatmap { create(:seatmap) }
    end
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

  factory :seatmap do
    # looks like this:
    #   A1 - A2 -
    #     B1 -  B2     (B1 is an accessible seat)
    name 'Default'
    csv "A1,,A2\r\n,B1+,,B2\r\n"
    json ['r[A1, ]_r[A2, ]_', '_a[B1, ]_r[B2, ]'].to_json
    seat_list 'A1,A2,B1,B2'
    rows 2
    columns 4
    image_url 'http://foo.com/seatmap.png'

    factory :custom_seatmap do
      seat_rows [%w(R1 R2),%w(S1 S2)]
      sequence(:name) { |n| "Seatmap #{n}" }
      after(:build) do |s,ev|
        s.parse_rows
      end
    end
  end

  
end
