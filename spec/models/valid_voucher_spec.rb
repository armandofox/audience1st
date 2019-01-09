require 'rails_helper'

describe ValidVoucher do

  describe "seats remaining" do 
    subject do
      ValidVoucher.new(
        :showdate => mock_model(Showdate, :valid? => true,
          :saleable_seats_left => showdate_seats,
          :sales_by_type => existing_sales),
        :vouchertype => mock_model(Vouchertype),
        :start_sales => 3.days.ago,
        :end_sales => 1.day.from_now,
        :max_sales_for_type => capacity_control)
    end
    context "without capacity controls should match showdate's saleable seats" do
      let(:showdate_seats)   { 10 }
      let(:capacity_control) { nil }
      let(:existing_sales)   { 10 }
      its(:seats_of_type_remaining)  { should == 10 }
    end
    context "should respect capacity controls even if more seats remain" do
      let(:showdate_seats)   { 10 }
      let(:capacity_control) { 3 } 
      let(:existing_sales)   { 2 } 
      its(:seats_of_type_remaining)  { should == 1 }
    end
    context "should be zero (not negative) even if capacity control already exceeded" do
      let(:showdate_seats)   { 10 }
      let(:capacity_control) { 3  }
      let(:existing_sales)   { 5  }
      its(:seats_of_type_remaining)  { should be_zero }
    end
    context "should respect overall capacity even if ticket capacity remains" do
      let(:showdate_seats)   { 10 }
      let(:capacity_control) { 15 }
      let(:existing_sales)   { 1  }
      its(:seats_of_type_remaining)  { should == 10 }
    end
    context "should respect overall capacity if show is advance-sold-out" do
      let(:showdate_seats)   { 0  }
      let(:capacity_control) { nil  }
      let(:existing_sales)   { 10 }
      its(:seats_of_type_remaining)  { should be_zero }
    end
  end

  describe "for comps" do
    context "that are self-service" do
      before(:each) do
        @vt = create(:comp_vouchertype, :offer_public => Vouchertype::ANYONE)
        @sd = create(:showdate)
        @vv = build(:valid_voucher, :vouchertype => @vt, :showdate => @sd)
      end
      it "should be invalid without a promo code" do
        expect(@vv).not_to be_valid
      end
      it "should be valid with a promo code" do
        @vv.promo_code = 'Gloof'
        expect(@vv).to be_valid
      end
    end
    context "that are non-self-service" do
      it "should be valid even without promo code"
    end
  end
  describe "promo code matching" do
    before :all do ; ValidVoucher.send(:public, :match_promo_code) ; end
    after :all do ; ValidVoucher.send(:protected, :match_promo_code) ; end
    context 'when promo code is blank' do
      before :each do ; @v = ValidVoucher.new(:promo_code => nil) ; end
      it 'should match empty string' do ;     @v.match_promo_code('').should be_truthy ; end
      it 'should match arbitrary string' do ; @v.match_promo_code('foo!').should be_truthy ; end
      it 'should match nil' do ;              @v.match_promo_code(nil).should be_truthy ; end
    end
    shared_examples_for 'nonblank promo code' do
      it 'should match exact string' do ;     @v.match_promo_code('foo').should be_truthy ; end
      it 'should be case-insensitive' do ;    @v.match_promo_code('FoO').should be_truthy ; end
      it 'should ignore whitespace' do ;      @v.match_promo_code(' Foo ').should be_truthy ; end
      it 'should not match partial string' do;@v.match_promo_code('fo').should be_falsey ; end
    end
    context '"foo"' do
      before :each do ; @v = ValidVoucher.new(:promo_code => 'foo') ; end
      it_should_behave_like 'nonblank promo code'
    end
    context 'multiple codes' do
      before :each do ; @v = ValidVoucher.new(:promo_code => 'bAr,Foo,BAZ') ; end
      it_should_behave_like 'nonblank promo code'
    end
  end


  describe 'bundle availability' do
    before :each do
      @anyone_bundle = create(:bundle)
      ValidVoucher.create(
        :vouchertype => @anyone_bundle,
        :max_sales_for_type => ValidVoucher::INFINITE,
        :start_sales => 1.week.ago,
        :end_sales => 1.week.from_now)
      @anyone = create(:customer)
    end
    it 'for generic bundle should be available to anyone' do
      ValidVoucher.bundles_available_to(@anyone, promo_code=nil).
        any? do |offer|
        offer.vouchertype == @anyone_bundle &&
          offer.max_sales_for_type == ValidVoucher::INFINITE
      end.should be_truthy
    end
  end



end
