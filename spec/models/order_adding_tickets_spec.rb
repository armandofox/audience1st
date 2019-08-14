require 'rails_helper'

describe Order, 'adding tickets' do
  # An Order is created and persisted the moment the customer tries to add something.
  # All the methods for adding stuff to orders require that the order be persisted first,
  # so that the added items inherit the correct order_id.
  before(:each) do
    @order = Order.create!(:processed_by => create(:customer))
    @vv = create(:valid_voucher, :max_sales_for_type => 2)
  end
  context 'when 2 seats left' do
    it 'works when 2 requested' do
      @order.add_tickets(@vv, 2)
      expect(@order.errors).to be_empty
      expect(@order.vouchers.size).to eq(2)
      expect(@order.vouchers.all? { |v| v.showdate_id == @vv.showdate_id }).to be_truthy
    end
    it 'fails when 3 requested' do
      @order.add_tickets(@vv, 3)
      expect(@order.vouchers.size).to be_zero
      expect(@order.errors[:base]).to include_match_for(/Only 2 seats are available/)
    end
    it 'succeeds if done by boxoffice' do
      @order.processed_by = create(:boxoffice)
      @order.add_tickets(@vv, 3)
      expect(@order.errors).to be_empty
      expect(@order.vouchers.size).to eq(3)
      expect(@order.vouchers.all? { |v| v.showdate_id == @vv.showdate_id }).to be_truthy
    end
  end
  it 'increases existing order' do
    expect { @order.add_tickets(@vv, 2) }.to change { @order.ticket_count }.by(2)
  end
  it 'empties order' do
    expect { @order.clear_contents! }.to change { @order.ticket_count}.to(0)
  end
end
