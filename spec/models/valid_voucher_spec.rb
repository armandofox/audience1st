require 'spec_helper'
include BasicModels

describe ValidVoucher do
  describe 'instantiation' do
    before(:each) do
      @vt_regular = BasicModels.create_revenue_vouchertype
      @customer = BasicModels.create_generic_customer
      @purch = mock_model(Purchasemethod, :purchase_medium => :cash)
      @showdate = mock_model(Showdate, :valid? => true)
      @logged_in_customer = Customer.boxoffice_daemon
      @now = @vt_regular.expiration_date - 2.months
      @comment = 'A comment'
      @valid_voucher =
        ValidVoucher.create!(:vouchertype => @vt_regular,
        :showdate => @showdate,
        :start_sales => @now - 1.month + 1.day,
        :end_sales => @now + 1.month - 1.day,
        :max_sales_for_type => 10)
    end
    describe 'of a non-bundle voucher' do
      context "successfully" do
        before(:each) do
          @vouchers =
            @valid_voucher.instantiate(@logged_in_customer,@purchasemethod,3,@comment)
        end
        it 'should have 3 vouchers' do ; @vouchers.length.should == 3 ; end
        it "should return valid vouchers" do ;@vouchers.each { |v| v.should be_valid } ; end
        it "should include the comment" do ; @vouchers.each { |v| v.comments.to_s.should == @comment } ; end
        it "should be marked processed by the logged-in customer" do
          @vouchers.each { |v| v.processed_by.should == @logged_in_customer }
        end
        it "should belong to the showdate" do
          @valid_voucher.showdate_id.should == @showdate.id
          @vouchers.each { |v| v.showdate_id.should == @showdate.id }
        end
        it "should not save the vouchers" do ; @vouchers.each { |v| v.should be_a_new_record  } ; end
      end
    end
    describe 'of a bundle voucher' do
      before :each do
        @vt_bundle = BasicModels.create_subscriber_vouchertype(:price => 25)
      end
      it 'should instantiate individual vouchers in bundle' do
        pending 'Refactoring of subscription sales using valid-vouchers'
      end
    end
  end

  describe 'adjusting' do
    shared_examples_for 'visible, zero capacity' do
      it { should be_visible }
      its(:explanation) { should_not be_blank }
      its(:max_sales_for_type) { should be_zero }
    end
    shared_examples_for 'invisible, zero capacity' do
      it { should_not be_visible }
      its(:explanation) { should_not be_blank }
      its(:max_sales_for_type) { should be_zero }
    end

    describe 'for reservation using existing voucher' do
      context 'when after deadline' do
        subject do
          s = BasicModels.create_one_showdate(1.day.from_now)
          v = ValidVoucher.new(:showdate => s, :end_sales => 1.day.ago, :max_sales_for_type => 100)
          v.adjust_for_customer_reservation
        end
        its(:explanation) { should == 'Advance reservations for this performance are closed' }
        its(:max_sales_for_type) { should be_zero }
      end
      context 'when valid' do
        subject do
          s = BasicModels.create_one_showdate(1.day.from_now)
          v = ValidVoucher.new(:showdate => s, :end_sales => 1.day.from_now, :max_sales_for_type => 10)
          v.adjust_for_customer_reservation
        end
        its(:max_sales_for_type) { should == 10 }
        its(:explanation) { should == '10 of these tickets remaining' }
      end
    end

    describe 'for visibility' do
      before :all do ; ValidVoucher.send(:public, :adjust_for_visibility) ; end
      subject do
        v = ValidVoucher.new
        v.stub!(:match_promo_code).and_return(promo_matched)
        v.stub!(:visible_to?).and_return(visible_to_customer)
        v.stub!(:offer_public_as_string).and_return('NOT YOU')
        v.adjust_for_visibility
        v
      end
      describe 'when promo code mismatch' do
        let(:promo_matched)    { nil }
        let(:visible_to_customer) { true }
        it_should_behave_like 'invisible, zero capacity'
        its(:explanation) { should == 'Promo code required' }
      end
      describe 'when invisible to customer' do
        let(:promo_matched)       { true }
        let(:visible_to_customer) { nil }
        it_should_behave_like 'invisible, zero capacity'
        its(:explanation) { should == 'Ticket sales of this type restricted to NOT YOU' }
      end
      describe 'when promo code matches and visible to customer' do
        let(:promo_matched)       { true }
        let(:visible_to_customer) { true }
        its(:explanation) { should be_blank }
      end
    end
    describe 'for showdate' do
      before :all do ; ValidVoucher.send(:public, :adjust_for_showdate) ; end
      subject do
        v = ValidVoucher.new(:showdate => the_showdate)
        v.adjust_for_showdate
        v
      end
      describe 'in the past' do
        let(:the_showdate) { mock_model(Showdate, :thedate => 1.day.ago) }
        it_should_behave_like 'invisible, zero capacity'
        its(:explanation) { should == 'Event date is in the past' }
      end
      describe 'that is sold out' do
        let(:the_showdate) { mock_model(Showdate, :thedate => 1.day.from_now, :really_sold_out? => true) }
        it_should_behave_like 'visible, zero capacity'
        its(:explanation) { should == 'Event is sold out' }
      end
    end

    describe "whose showdate's advance sales have ended" do
      before :each do
        ValidVoucher.send(:public, :adjust_for_sales_dates)
        @showdate = mock_model(Showdate, :thedate => 1.day.from_now, :saleable_seats_left => 10, :end_advance_sales => 1.day.ago)
        @v = ValidVoucher.new(:start_sales => 2.days.ago, :end_sales => 1.week.from_now,
          :showdate => @showdate)
        @v.adjust_for_sales_dates
        @v
      end
      it 'should have no seats available' do
        @v.max_sales_for_type.should be_zero
      end
      it 'should say advance sales are closed' do
        @v.explanation.should == 'Advance sales for this performance are closed'
      end
    end

    describe 'for per-ticket-type sales dates' do
      before :all do ; ValidVoucher.send(:public, :adjust_for_sales_dates) ; end
      subject do
        v = ValidVoucher.new(:start_sales => starts, :end_sales => ends, :showdate => mock_model(Showdate, :end_advance_sales => 1.day.from_now))
        v.adjust_for_sales_dates
        v
      end
      describe 'before start of sales' do
        let(:starts) { @time = 2.days.from_now }
        let(:ends)   { 3.days.from_now }
        it_should_behave_like 'visible, zero capacity'
        its(:explanation) { should == "Tickets of this type not on sale until #{@time.to_formatted_s(:showtime)}" }
      end
      describe 'after end of sales' do
        let(:starts) { 2.days.ago }
        let(:ends)   { @time = 1.day.ago }
        it_should_behave_like 'visible, zero capacity'
        its(:explanation) { should == "Tickets of this type not sold after #{@time.to_formatted_s(:showtime)}" }
      end
      describe 'when neither condition applies' do
        let(:starts) { 2.days.ago }
        let(:ends)   { 1.day.from_now }
        its(:explanation) { should be_blank }
      end
    end

    describe 'for capacity' do
      before :all do ; ValidVoucher.send(:public, :adjust_for_capacity) ; end
      subject do
        v = ValidVoucher.new(:showdate => mock_model(Showdate))
        v.stub!(:seats_of_type_remaining).and_return(seats)
        v.adjust_for_capacity
        v
      end
      describe 'when zero seats remain' do
        let(:seats) { 0 }
        its(:max_sales_for_type) { should be_zero }
        its(:explanation) { should == 'No seats remaining for tickets of this type' }
      end
      describe 'when one or more seats remain' do
        let(:seats) { 5 }
        its(:max_sales_for_type) { should == 5 }
        its(:explanation) { should == '5 of these tickets remaining' }
      end
    end

  end

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

  describe "promo code matching" do
    before :all do ; ValidVoucher.send(:public, :match_promo_code) ; end
    after :all do ; ValidVoucher.send(:protected, :match_promo_code) ; end
    context 'when promo code is blank' do
      before :each do ; @v = ValidVoucher.new(:promo_code => nil) ; end
      it 'should match empty string' do ;     @v.match_promo_code('').should be_true ; end
      it 'should match arbitrary string' do ; @v.match_promo_code('foo!').should be_true ; end
      it 'should match nil' do ;              @v.match_promo_code(nil).should be_true ; end
    end
    shared_examples_for 'nonblank promo code' do
      it 'should match exact string' do ;     @v.match_promo_code('foo').should be_true ; end
      it 'should be case-insensitive' do ;    @v.match_promo_code('FoO').should be_true ; end
      it 'should ignore whitespace' do ;      @v.match_promo_code(' Foo ').should be_true ; end
      it 'should not match partial string' do;@v.match_promo_code('fo').should be_false ; end
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
      @anyone_bundle = BasicModels.create_bundle_vouchertype
      @anyone_bundle_availability = ValidVoucher.new(
        :vouchertype => @anyone_bundle,
        :max_sales_for_type => ValidVoucher::INFINITE,
        :start_sales => 1.week.ago,
        :end_sales => 1.week.from_now)
      @anyone = BasicModels.create_generic_customer
    end
    it 'for generic bundle should be available to anyone' do
      ValidVoucher.bundles_available_to(@anyone, admin=nil, promo_code=nil).
        any? do |offer|
        offer.vouchertype == @anyone_bundle &&
          offer.max_sales_for_type == ValidVoucher::INFINITE
      end.should be_true
    end
  end



end
