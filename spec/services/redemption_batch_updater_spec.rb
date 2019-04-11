require 'rails_helper'

describe 'editing existing' do
  before(:each) do
    @sd1 = create(:showdate)
    @sd2 = create(:showdate, :show => @sd1.show, :thedate => @sd1.thedate + 1.day)
    @vt1 = create(:revenue_vouchertype)
    @vt2 = create(:revenue_vouchertype)
    @vv1 = create(:valid_voucher, :showdate => @sd1, :vouchertype => @vt1)
    @vv2 = create(:valid_voucher, :showdate => @sd2, :vouchertype => @vt2)
  end

  describe 'selective update' do
    before(:each) do
      @orig_end_sales = @vv1.end_sales
      @new_start_sales = @vv1.end_sales - 1.month
      @vv_params = {"start_sales(1i)"=> @new_start_sales.year.to_s,
        "start_sales(2i)"=> @new_start_sales.month.to_s,
        "start_sales(3i)"=> @new_start_sales.day.to_s,
        "start_sales(4i)"=> @new_start_sales.hour.to_s,
        "start_sales(5i)"=> @new_start_sales.min.to_s,
        "promo_code" => "XYZ",
        "before_showtime" => 20.minutes,
        "max_sales_for_type" => "33"
      }.symbolize_keys
      @u = RedemptionBatchUpdater.new([@vt1],[@sd1],:valid_voucher_params => @vv_params)
    end
    after(:each) do
      expect(@u.error_message).to be_blank
    end
    describe 'preserves' do
      specify 'start sales' do
        @u.preserve = {"start_sales" => "1"}
        expect { @u.update }.not_to change { @vv1.start_sales }
      end
      specify 'promo code' do
        @u.preserve = {"start_sales" => "1", "promo_code" => "1"}
        expect { @u.update }.not_to change { @vv1.promo_code }
        expect { @u.update }.not_to change { @vv1.start_sales }
      end
      specify 'end sales' do
        @u.preserve = {"end_sales" => "1"}
        expect { @u.update }.not_to change { @vv1.end_sales }
      end
      specify 'max sales for type' do
        @u.preserve = {"max_sales_for_type" => "1"}
        expect { @u.update }.not_to change { @vv1.max_sales_for_type }
      end
    end
    describe 'overwrites' do
      specify 'start sales' do
        @u.update
        @vv1.reload
        expect(@vv1.start_sales.to_time).to eq(@new_start_sales)
      end
      specify 'end sales' do
        @u.update
        @vv1.reload
        expect(@vv1.end_sales).to eq(@vv1.showdate.thedate - 20.minutes)
      end
      specify 'promo, even if blank' do
        @vv_params["promo_code"] = ''
        @u.valid_voucher_params = @vv_params
        @u.update
        expect(@vv1.promo_code).to be_blank
      end
      specify 'max sales for type (finite)' do
        @u.update
        @vv1.reload
        expect(@vv1.max_sales_for_type).to eq(33)
      end
    end
  end
  
  describe 'when validity errors' do
    before(:each) do
      @params = {:before_showtime => 4.hours, :max_sales_for_type => 77}
      @u = RedemptionBatchUpdater.new([@sd1,@sd2],[@vt1,@vt2], :valid_voucher_params => @params)
      # invalid because start_sales not specified
    end
    it 'gives error' do
      @u.update
      expect(@u.error_message).to match /Start sales can't be blank/ # '
    end
    it 'does not update existing redemption 1' do
      expect(@vv1).not_to receive(:save)
    end
    it 'does not update existing redemption 2' do
      expect(@vv2).not_to receive(:save)
    end
  end
  describe 'updates' do
    before(:each) do
      params = {:before_showtime => 4.hours, :max_sales_for_type => 77, :start_sales => @sd1.thedate - 2.weeks}
      @u = RedemptionBatchUpdater.new([@sd1,@sd2], [@vt1,@vt2], :valid_voucher_params => params)
      expect(@u.update).to be_truthy
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
    RedemptionBatchUpdater.new([@sd2],[@vt2], :valid_voucher_params => params).update
    @vv2 = ValidVoucher.find_by!(:showdate => @sd2, :vouchertype => @vt2)
    expect(@vv2.end_sales).to eq(@sd2.thedate - 3.hours)
  end
  describe 'updates existing/creates new with correct' do
    before(:each) do
      @vv2.destroy
      params = {:before_showtime => 3.hours, :max_sales_for_type => 77, :start_sales => @sd1.thedate - 2.weeks}
      @u = RedemptionBatchUpdater.new([@sd1,@sd2], [@vt1,@vt2], :valid_voucher_params => params)
      @u.update
      @vv1.reload
      @vv2 = ValidVoucher.find_by!(:showdate => @sd2, :vouchertype => @vt2)
    end
    specify 'existing VV end sales' do ; expect(@vv1.end_sales).to eq(@sd1.thedate - 3.hours) ; end
    specify 'new VV end sales' do ; expect(@vv2.end_sales).to eq(@sd2.thedate - 3.hours) ; end
    specify 'existing VV max sales' do ; expect(@vv1.max_sales_for_type).to eq(77) ; end
    specify 'new VV max sales' do ; expect(@vv2.max_sales_for_type).to eq(77) ; end
  end
end
