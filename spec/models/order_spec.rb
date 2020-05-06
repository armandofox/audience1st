require 'rails_helper'

describe Order do
  before :each do
    @the_customer = create(:customer)
    @the_processed_by = create(:customer)
    @order = Order.create!(:processed_by => @the_processed_by)
  end
  describe 'new order' do
    subject { Order.new }
    it { is_expected.not_to be_a_gift }
    it { is_expected.not_to be_completed }
    it { is_expected.not_to be_walkup }
    its(:items) { should be_empty }
    its(:cart_empty?) { should be_truthy }
    its(:total_price) { should be_zero }
    its(:refundable_to_credit_card?) { should be_falsey }
    its(:errors) { should be_empty }
    its(:comments) { should be_blank }
  end

  describe 'creating from bare donation' do
    before(:each) { @order = Order.new_from_donation(10.00, AccountCode.default_account_code, create(:customer)) }
    it 'should not be completed' do ; expect(@order).not_to be_completed ; end
    it 'should include a donation' do ; expect(@order.includes_donation?).to be_truthy  ; end
    it 'should_not be_a_gift' do ; expect(@order).not_to be_a_gift ; end
    it 'should not be ready' do ; expect(@order).not_to be_ready_for_purchase, @order.errors.full_messages ; end
    it 'should not show as empty' do ; expect(@order.cart_empty?).to be_falsey ; end
    it 'should be ready when purchasemethod and processed_by are set' do
      @order.purchasemethod = Purchasemethod.default
      @order.processed_by = @the_customer
      expect(@order).to be_ready_for_purchase
    end
  end

  describe 'marshalling' do
    it 'donation' do
      @order = Order.create!(:processed_by => create(:customer))
      @order.add_donation(Donation.from_amount_and_account_code_id(10,nil))
      @order.save!
      @unserialized = Order.find(@order.id)
      expect(@unserialized.cart_empty?).to be_falsey
    end
    it 'order with donations and tickets' do
      @order.add_donation(Donation.from_amount_and_account_code_id(10,nil))
      @order.add_tickets_without_capacity_checks(create(:valid_voucher), 3)
      @order.save!
      reloaded = Order.find(@order.id)
      expect(reloaded.ticket_count).to eq(3)
      expect(reloaded.donation.amount).to eq(10)
    end

  end

  describe 'guest checkout' do
    before :each do
      @order = Order.create!(:processed_by => Customer.anonymous_customer)
      @order.add_tickets_without_capacity_checks(create(:valid_voucher), 2)
    end
    context 'allowed when includes' do
      specify 'regular tickets only' do
        expect(@order).to be_ok_for_guest_checkout
      end
      specify 'donation' do
        @order.add_donation(Donation.from_amount_and_account_code_id(10,nil))
        expect(@order).to be_ok_for_guest_checkout
      end
    end
    context 'not allowed when includes' do
      specify 'subscription' do
        @order.add_tickets_without_capacity_checks(create(:valid_voucher, :vouchertype => create(:bundle, :subscription => true)), 1)
        expect(@order).not_to be_ok_for_guest_checkout
      end
      specify 'class enrollment' do
        some_class = create(:show, :event_type => 'Class')
        @order.add_tickets_without_capacity_checks(create(:valid_voucher, :showdate => create(:showdate, :show => some_class)), 1)
        expect(@order).not_to be_ok_for_guest_checkout
      end
      specify 'retail items' do
        @order.add_tickets_without_capacity_checks(create(:valid_voucher, :vouchertype => create(:nonticket_vouchertype)), 1)
        expect(@order).not_to be_ok_for_guest_checkout
      end
    end
  end

  describe 'showdate notes' do
    before :each do
      @s1 = create(:show, :patron_notes => 'Enjoy')
      @s2 = create(:show)
      @v1 = create(:valid_voucher, :showdate => create(:showdate, :show => @s1))
      @v2 = create(:valid_voucher, :showdate => create(:showdate, :show => @s2))
      @o = Order.create!(:processed_by => create(:boxoffice))
    end
    it 'includes de-duplicated patron notes' do
      @o.add_tickets_without_capacity_checks(@v1, 2)
      @o.add_tickets_without_capacity_checks(@v2, 2)
      expect(@o.collect_notes).to eq(['Enjoy'])
    end
    it "doesn't include blank notes" do
      @o.add_tickets_without_capacity_checks(@v2,2)
      expect(@o.collect_notes).to eq([])
    end
    it "doesn't barf on donation-only orders" do
      @o.add_donation(Donation.new(:amount => 5))
      expect(@o.collect_notes).to eq([])
    end
  end

  describe 'gift' do
    before :each do ; @c = create(:customer) ; @p = create(:customer) ; end
    context 'sent to purchaser' do
      subject { Order.new(:customer => @c, :purchaser => @p, :ship_to_purchaser => true) }
      it { is_expected.to be_a_gift }
      its(:ship_to) { should == @p }
    end
    context 'sent to recipient' do
      subject { Order.new(:customer => @c, :purchaser => @p, :ship_to_purchaser => false) }
      it { is_expected.to be_a_gift }
      its(:ship_to) { should == @c }
    end
    context 'not a gift' do
      subject { Order.new(:customer => @c, :purchaser => @c) }
      it { is_expected.not_to be_a_gift }
      its(:ship_to) { should == @c }
    end
  end

  describe 'walkup confirmation' do
    before :each do
      @o = Order.create!(:processed_by => create(:boxoffice))
      allow(@o).to receive(:purchase_medium).and_return("Cash")
      @v = create(:revenue_vouchertype,:price => 7)
      @vv = create(:valid_voucher, :vouchertype => @v)
    end
    [ 1,0,"$5.00 donation (total $5.00) paid by Cash",
      1,2, "$5.00 donation and 2 tickets (total $19.00) paid by Cash" ,
      0,2, "2 tickets (total $14.00) paid by Cash",
      1,1, "$5.00 donation and 1 ticket (total $12.00) paid by Cash"
    ].each_slice(3) do |donations,tickets,message|
      specify "#{donations} donations and #{tickets} tickets" do
        @o.add_donation(Donation.new(:amount => 5)) if donations > 0
        @o.add_tickets_without_capacity_checks(@vv,tickets) if tickets > 0
        expect(@o.walkup_confirmation_notice).to eq(message)
      end
    end
  end

end
