require 'rails_helper'

describe Vouchertype do
  before :each do
    @now = Time.current.at_end_of_season - 6.months
  end
  describe 'visibility' do
    before :each do
      @customers =  {}
      %w[patron staff walkup boxoffice].each do |c|
        @customers[c.to_sym] = Customer.new { |cust| cust.role = Customer.role_value(c) }
        @customers[name = (c + '_subscriber').to_sym] = Customer.new do |cust|
          cust.role = Customer.role_value(c)
        end
        allow(@customers[name]).to receive(:subscriber?).and_return(true)
      end
    end
    context 'of boxoffice voucher' do
      subject { Vouchertype.new :offer_public => Vouchertype::BOXOFFICE }
      it { is_expected.not_to be_visible_to(@customers[:patron]) }
      it { is_expected.not_to be_visible_to(@customers[:walkup]) }
    end
    context 'of subscriber voucher' do
      subject { Vouchertype.new :offer_public => Vouchertype::SUBSCRIBERS }
      it { is_expected.not_to be_visible_to(@customers[:patron]) }
      it { is_expected.to     be_visible_to(@customers[:patron_subscriber]) }
    end
    context 'of general-availability voucher' do
      subject { Vouchertype.new :offer_public => Vouchertype::ANYONE }
      it { is_expected.to     be_visible_to(@customers[:patron_subscriber]) }
      it { is_expected.to     be_visible_to(@customers[:patron]) }
      it { is_expected.to     be_visible_to(@customers[:walkup]) }
    end
    context 'of external reseller voucher' do
      subject { Vouchertype.new :offer_public => Vouchertype::EXTERNAL }
      it { is_expected.not_to be_visible_to(@customers[:patron]) }
      it { is_expected.not_to be_visible_to(@customers[:patron_subscriber]) }
      it { is_expected.not_to be_visible_to(@customers[:boxoffice]) }
      it { is_expected.not_to be_visible_to(@customers[:walkup]) }
    end
  end
  describe "validations" do
    before(:each) do
      @vt = Vouchertype.new(:price => 1.0,
        :offer_public => Vouchertype::ANYONE,
        :category => 'revenue',
        :name => "Example",
        :subscription => false,
        :walkup_sale_allowed => true,
        :comments => "A comment",
        :account_code => AccountCode.default_account_code,
        :season => @now.year
        )
    end
    describe "vouchertypes in general" do
      it "should be valid with valid attributes" do
        expect(@vt).to be_valid
      end
      it "may not be zero-price, even if accessible to boxoffice only" do
        @vt.price = 0.0
        @vt.offer_public = Vouchertype::BOXOFFICE
        expect(@vt).not_to be_valid
      end
      it "may not be zero-price even if provided by external reseller as a comp" do
        @vt.price = 0.0
        @vt.offer_public = Vouchertype::EXTERNAL
        expect(@vt).not_to be_valid
      end
      it "should be valid for redemption now" do
        expect(@vt).to be_valid_now
      end
      it "should not have a bogus offer-to-whom field" do
        @vt.offer_public = 999
        expect(@vt).not_to be_valid
      end
      it "should not have a negative price" do
        @vt = Vouchertype.new(:price => -1.0)
        expect(@vt).not_to be_valid
      end
      it "should not be sold as walkup if it's a subscription" do
        @vt.subscription = true
        @vt.walkup_sale_allowed = true
        expect(@vt).not_to be_valid
        expect(@vt.errors[:base]).to include_match_for(/walkup sales/i)
      end
    end
    describe "nonticket vouchertypes" do
      it "should be valid" do
        @vtn = Vouchertype.new(
          :price => 5.0,
          :category => 'nonticket',
          :offer_public => Vouchertype::BOXOFFICE,
          :name => "Fee",
          :subscription => false,
          :walkup_sale_allowed => true,
          :comments => "A comment",
          :account_code => AccountCode.default_account_code,
          :season => @now.year
          )
        expect(@vtn).to be_valid
      end
    end
    describe "bundles" do
      before :each do
        args = {
          :offer_public => Vouchertype::BOXOFFICE,
          :subscription => false,
          :walkup_sale_allowed => true,
          :comments => "A comment",
          :account_code => AccountCode.default_account_code,
          :season => @now.year
        }
        @vt_free = create(:comp_vouchertype)
        @vt_notfree = create(:revenue_vouchertype)
        @vtb = Vouchertype.new(args.merge({ :category => 'bundle', :name => "Bundle"}))
      end
      it "should be invalid if contains any nonzero-price vouchers" do
        @vtb.included_vouchers = {@vt_free.id => 1, @vt_notfree.id => 1}
        expect(@vtb).not_to be_valid
        expect(@vtb.errors.full_messages).to include("Bundles cannot include revenue vouchers (#{@vt_notfree.name})"), @vtb.errors.full_messages.join(',')
      end
      it "should  be valid with only zero-price vouchers" do
        @vtb.included_vouchers = {@vt_free.id => 1, @vt_notfree.id => 0}
      end
    end
  end
  describe 'lifecycle' do
    before :each do
      @b1 = create(:vouchertype_included_in_bundle)
      @b2 = create(:vouchertype_included_in_bundle)
      @v = create(:bundle, :including => { @b1 => 1, @b2 => 2 })
      @v2 = create(:bundle, :including => { @b1 => 2, @b2 => 1 })
    end
    describe 'deleting a vouchertype included in a bundle' do
      it 'adjusts the bundle' do
        @b1.destroy
        @v.reload
        expect(@v.included_vouchers.keys.map(&:to_i)).not_to include(@b1.id)
      end
    end
    it 'should be linked to a new valid-voucher with season start/end dates as default when created' do
      expect(@v.valid_vouchers.length).to eq(1)
    end
    it 'should destroy its valid-voucher when destroyed' do
      saved_id = @v.id
      @v.destroy
      expect(ValidVoucher.find_by_vouchertype_id(saved_id)).to be_nil
    end
    describe 'attempting to change to a non-bundle after creation' do
      before :each do
        @result = @v.update_attributes(:category => 'revenue')
      end
      it 'should fail' do ; expect(@result).to be_falsey ; end
      it 'should explain why' do
        expect(@v.errors[:category]).to include_match_for(/cannot be changed/)
      end
      it 'should not change the category' do
        @v.reload
        expect(@v.category).to eq('bundle')
      end
    end
  end
end
