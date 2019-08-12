require 'rails_helper'

describe Showdate do
  before(:each) do
    @house_cap = 12
    @max_advance_sales = 10
    @showdate = create(:showdate,
      :show => create(:show, :house_capacity => @house_cap),
      :end_advance_sales => Time.current - 5.minutes,
      :max_advance_sales => @max_advance_sales)
    4.times { create(:subscriber_voucher, :showdate => @showdate) }
    3.times { create(:comp_voucher,       :showdate => @showdate) }
    2.times { create(:revenue_voucher, :amount => 11,  :showdate => @showdate) }
    1.times { create(:nonticket_item,     :showdate => @showdate) }
  end
  it "has 9 seats sold" do
    expect(@showdate.vouchers.count).to eq(9)
  end
  it "has 10 actual vouchers" do
    expect(@showdate.all_vouchers.count).to eq(10)
  end
  it "has 1 nonticket product" do
    nonticket = @showdate.all_vouchers - @showdate.vouchers
    expect(nonticket.size).to eq(1)
    expect(nonticket.first.category).to eq('nonticket')
  end
  it 'revenue is based on seats only' do
    # only 2 seats were revenue seats
    expect(@showdate.revenue).to eq(22.00)
  end
  describe "capacity" do
    shared_examples "for normal sales" do
      # house cap 12, max sales 10, sold 9
      it "computes total sales" do
        expect(@showdate.compute_total_sales).to eq(9)
        expect(@showdate.compute_advance_sales).to eq(9)
      end
      it "computes seats left" do
        expect(@showdate.total_seats_left).to eq(3)
      end
      it "is not affected by nonticket items" do
        create(:nonticket_item, :showdate => @showdate)
        expect(@showdate.total_seats_left).to eq(3)
      end
      it "computes percent of max sales" do
        # 9 seats sold out of max sales of 10 = 90%
        expect(@showdate.percent_sold).to eq(90)
      end
      it "computes percent of house" do
        # 9 seats sold out of house cap of 12 = 75%
        expect(@showdate.percent_of_house).to eq(75)
      end
    end
    describe "when house is partly sold" do
      it_should_behave_like "for normal sales"
      it "computes saleable seats left" do
        expect(@showdate.saleable_seats_left).to eq(1)
      end
    end
    describe "when house is oversold" do
      before(:each) do
        4.times do
          create(:revenue_voucher, :showdate => @showdate)
        end
      end
      it "shows zero (not negative) seats remaining" do
        expect(@showdate.total_seats_left).to eq(0)
        expect(@showdate.saleable_seats_left).to eq(0)
      end
    end
    describe "when sold beyond max sales but not house cap" do
      before(:each) do
        @showdate.update_attribute(:max_advance_sales, 8)
      end
      it "computes saleable seats left" do
        expect(@showdate.saleable_seats_left).to eq(0)
      end
      it "shows zero (not negative) seats remaining" do
        expect(@showdate.saleable_seats_left).to eq(0)
      end
      it 'shows sold-out if max sales is zero' do
        @showdate.update_attributes!(:max_advance_sales => 0)
        expect(@showdate).to be_really_sold_out
      end
    end
  end
end
