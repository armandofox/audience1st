require 'rails_helper'

describe Show do

  it "should be searchable case-insensitive" do
    @s = create(:show, :name => "The Last Five Years")
    expect(Show.find_unique(" the last FIVE Years")).to eq(@s)
  end
  specify "revenue per seat should be zero (not exception) if zero vouchers sold" do
    @s = create(:show)
    expect { @s.revenue_per_seat }.not_to raise_error
    expect(@s.revenue_per_seat).to be_zero
  end
end
