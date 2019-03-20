require 'rails_helper'

describe 'editing existing', :focus => true do
  before(:each) do
    @sd1 = create(:showdate)
    @sd2 = create(:showdate, :show => @sd1.show, :thedate => @sd1.thedate + 1.day)
    @vt1 = create(:revenue_vouchertype)
    @vt2 = create(:revenue_vouchertype)
    @vv1 = create(:valid_voucher, :showdate => @sd1, :vouchertype => @vt1)
    @vv2 = create(:valid_voucher, :showdate => @sd2, :vouchertype => @vt2)
  end

  describe 'selective update' do
    it 'overrides 

  it 'does not update if validity errors' do
    params = {:before_showtime => 4.hours, :max_sales_for_type => 77}
    # invalid because start_sales not specified
    expect { ValidVoucher.add_vouchertypes_to_showdates!([@sd1,@sd2], [@vt1,@vt2], params) }.
      to raise_error(ValidVoucher::CannotAddVouchertypeToMultipleShowdates)
  end
  describe 'updates' do
    before(:each) do
      params = {:before_showtime => 4.hours, :max_sales_for_type => 77, :start_sales => @sd1.thedate - 2.weeks}
      ValidVoucher.add_vouchertypes_to_showdates!([@sd1,@sd2], [@vt1,@vt2], params)
      @vv1.reload
      @vv2.reload
    end
    specify 'show 1 start sales' do ; expect(@vv1.start_sales).to eq(@sd1.thedate - 2.weeks) ; end
    specify 'show 2 start sales to match show 1' do ; expect(@vv2.start_sales).to eq(@sd1.thedate - 2.weeks) ; end
    specify 'show 1 end sales to 4h before showtime' do ; expect(@vv1.end_sales).to eq(@sd1.thedate - 4.hours) ; end
    specify 'show 2 end sales to 4h before showtime' do ; expect(@vv2.end_sales).to eq(@sd2.thedate - 4.hours) ; end
    specify 'show 1 max sales' do ; expect(@vv1.max_sales_for_type).to eq(77) ; end
    specify 'show 2 max sales' do ; expect(@vv2.max_sales_for_type).to eq(77) ; end
  end
  it 'creates new with correct params' do
    @vv2.destroy
    params = {:before_showtime => 3.hours, :max_sales_for_type => 77, :start_sales => @sd1.thedate - 2.weeks}
    ValidVoucher.add_vouchertypes_to_showdates!([@sd2],[@vt2], params)
    @vv2 = ValidVoucher.find_by!(:showdate => @sd2, :vouchertype => @vt2)
    expect(@vv2.end_sales).to eq(@sd2.thedate - 3.hours)
  end
  describe 'updates existing/creates new with correct' do
    before(:each) do
      @vv2.destroy
      params = {:before_showtime => 3.hours, :max_sales_for_type => 77, :start_sales => @sd1.thedate - 2.weeks}
      ValidVoucher.add_vouchertypes_to_showdates!([@sd1,@sd2], [@vt1,@vt2], params)
      @vv1.reload
      @vv2 = ValidVoucher.find_by!(:showdate => @sd2, :vouchertype => @vt2)
    end
    specify 'existing VV end sales' do ; expect(@vv1.end_sales).to eq(@sd1.thedate - 3.hours) ; end
    specify 'new VV end sales' do ; expect(@vv2.end_sales).to eq(@sd2.thedate - 3.hours) ; end
    specify 'existing VV max sales' do ; expect(@vv1.max_sales_for_type).to eq(77) ; end
    specify 'new VV max sales' do ; expect(@vv2.max_sales_for_type).to eq(77) ; end
  end
end
end
