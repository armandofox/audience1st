require 'rails_helper'

describe Order, 'adding' do
  before :each do 
    @order = Order.create!(:processed_by => create(:customer)) # generic customer
    @vv = create(:valid_voucher)
  end
  describe 'retail items' do
    before :each do
      @thing = Array.new(2) { |i| RetailItem.from_amount_description_and_account_code_id(4*(i+1), "Thing #{i}") }
    end
    it 'has none initially' do
      expect(@order.retail_items).to eq([])
    end
    it 'can include several' do
      @order.add_retail_item(@thing[0])
      @order.add_retail_item(@thing[1])
      expect(@order.retail_items).to eq(@thing)
      expect(@order.total_price).to eq(12.0)
    end
    it 'includes them in price' do
      expect { @order.add_retail_item(@thing[0]) }.to change { @order.total_price }.by(4)
    end
    it 'makes order nonempty' do
      expect(@order.cart_empty?).to be_truthy
      @order.add_retail_item(@thing[0])
      expect(@order.cart_empty?).not_to be_truthy
    end
    it 'includes them in count' do
      expect { @order.add_retail_item(@thing[0]) }.to change { @order.item_count }.by(1)
    end
    it 'excludes them from ticket count' do
      expect { @order.add_retail_item(@thing[0]) }.to_not change { @order.ticket_count }
    end
  end
  describe 'donations' do
    before :each do ; @donation = build(:donation, :amount => 17) ; end
    it 'should add donation' do
      @order.add_donation(@donation)
      expect(@order.donation).to be_a_kind_of(Donation)
    end
    it 'should serialize donation' do
      @order.donation = @donation
      @order.save!
      reloaded = Order.find(@order.id)
      expect(reloaded.donation.amount).to eq(@donation.amount)
      expect(reloaded.donation.account_code_id).to eq(@donation.account_code_id)
    end
  end
  describe 'and getting total price' do
    it 'without donation' do
      vv2 = create(:valid_voucher)
      expect { @order.add_tickets_without_capacity_checks(@vv, 2) ; @order.add_tickets_without_capacity_checks(vv2, 3) }.to change { @order.total_price }.to(60.0)
    end
    describe 'with donation' do
      before :each do ; @donation = build(:donation, :amount => 17) ; end
      specify 'and tickets' do
        @order.add_tickets_without_capacity_checks(@vv, 2)
        @order.add_donation(@donation)   # at $17
        expect(@order.total_price).to eq(41.0)
      end
      specify 'with donation only' do
        @order.add_donation(@donation)
        @order.add_donation(@donation)   # should be idempotent
        expect(@order.total_price).to eq(17.0)
      end
    end
  end
end
