require 'rails_helper'

describe 'ValidVoucher' do

  describe 'editing existing', :focus => true do
    before(:each) do
      @sd1 = create(:showdate)
      @sd2 = create(:showdate, :show => @sd1.show, :thedate => @sd1.thedate + 1.day)
      @vt1 = create(:revenue_vouchertype)
      @vt2 = create(:revenue_vouchertype)
      @vv1 = create(:valid_voucher, :showdate => @sd1, :vouchertype => @vt1)
      @vv2 = create(:valid_voucher, :showdate => @sd2, :vouchertype => @vt2)
      @params = {:before_showtime => 4.hours, :max_sales_for_type => 77}
    end
    it 'does not update if validity errors' do
      expect { ValidVoucher.add_vouchertypes_to_showdates!([@sd1,@sd2], [@vt1,@vt2], @params) }.
        to raise_error(ValidVoucher::CannotAddVouchertypeToMultipleShowdates)
    end
    describe 'with valid attributes' do
      before(:each) do
        @params[:start_sales] = (@sd1.thedate - 1.week).change(:minute => 0)
      end
      it 'updates attributes' do
        ValidVoucher.add_vouchertypes_to_showdates!([@sd1,@sd2], [@vt1,@vt2], @params)
        expect(@vv1.end_sales).to eq(@sd1.thedate - 4.hours)
        expect(@vv2.end_sales).to eq(@sd2.thedate - 4.hours)
        expect(@vv1.max_sales_for_type).to eq(77)
        expect(@vv2.max_sales_for_type).to eq(77)
      end
      it 'updates attributes on existing and creates new if nonexisting' do
        @vv2.destroy
        ValidVoucher.add_vouchertypes_to_showdates!([@sd1,@sd2], [@vt1,@vt2], @params)
        expect(@vv1.end_sales).to eq(@sd1.thedate - 4.hours)
        expect(@vv2.end_sales).to eq(@sd2.thedate - 4.hours)
        expect(@vv1.max_sales_for_type).to eq(77)
        expect(@vv2.max_sales_for_type).to eq(77)
      end
    end
  end
end
