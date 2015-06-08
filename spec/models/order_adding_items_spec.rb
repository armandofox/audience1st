require 'spec_helper'

describe Order, 'adding' do
  before :each do 
    @vv = create(:valid_voucher)
    @order = Order.new 
  end
  describe 'retail items' do
    before :each do
      @thing = Array.new(2) { |i| RetailItem.from_amount_description_and_account_code_id(4*(i+1), "Thing #{i}") }
    end
    it 'has none initially' do
      @order.retail_items.should == []
    end
    it 'can include several' do
      @order.add_retail_item(@thing[0])
      @order.add_retail_item(@thing[1])
      @order.retail_items.should == @thing
      @order.total_price.should == 12.0
    end
    it 'includes them in price' do
      expect { @order.add_retail_item(@thing[0]) }.to change { @order.total_price }.by(4)
    end
    it 'includes them in count' do
      expect { @order.add_retail_item(@thing[0]) }.to change { @order.item_count }.by(1)
    end
    it 'excludes them from ticket count' do
      expect { @order.add_retail_item(@thing[0]) }.to_not change { @order.ticket_count }
    end
  end
  describe 'tickets' do
    before :each do  ;    @order.add_tickets(@vv, 3) ;   end
    it 'should work when cart is empty' do ; @order.ticket_count.should == 3  ; end
    it 'should add to existing tickets' do
      expect { @order.add_tickets(@vv, 2) }.to change { @order.ticket_count }.by(2)
    end
    it 'should empty cart' do
      expect { @order.empty_cart! }.to change { @order.ticket_count}.to(0)
    end
    it 'should serialize cart' do
      @order.save!
      reloaded = Order.find(@order.id)
      reloaded.ticket_count.should == 3
    end
  end
  describe 'donations' do
    before :each do ; @donation = build(:donation, :amount => 17) ; end
    it 'should add donation' do
      @order.add_donation(@donation)
      @order.donation.should be_a_kind_of(Donation)
    end
    it 'should serialize donation' do
      @order.donation = @donation
      @order.save!
      reloaded = Order.find(@order.id)
      reloaded.donation.amount.should == @donation.amount
      reloaded.donation.account_code_id.should == @donation.account_code_id
    end
  end
  describe 'and getting total price' do
    it 'without donation' do
      vv2 = create(:valid_voucher)
      expect { @order.add_tickets(@vv, 2) ; @order.add_tickets(vv2, 3) }.to change { @order.total_price }.to(60.0)
    end
    describe 'with donation' do
      before :each do ; @donation = build(:donation, :amount => 17) ; end
      specify 'and tickets' do
        @order.add_tickets(@vv, 2)
        @order.add_donation(@donation)   # at $17
        @order.total_price.should == 41.0
      end
      specify 'with donation only' do
        @order.add_donation(@donation)
        @order.add_donation(@donation)   # should be idempotent
        @order.total_price.should == 17.0
      end
    end
  end
end
