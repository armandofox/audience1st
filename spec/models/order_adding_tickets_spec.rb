require 'rails_helper'

describe 'Order adding tickets' do
  # An Order is created and persisted the moment the customer tries to add something.
  # All the methods for adding stuff to orders require that the order be persisted first,
  # so that the added items inherit the correct order_id.
  before(:each) do
    @order = create(:order)
    @vv = create(:valid_voucher, :max_sales_for_type => 2)
  end
  context 'if admin' do
    before :each do
      @boxoffice_user = create(:customer, :role => 'boxoffice')
      @order.processed_by = @boxoffice_user
      @params = {@vv.id => 3}
    end
    it 'can add tickets even if beyond max sales limit' do
      @vv.showdate.update_attributes!(:max_advance_sales => 2)
      expect { @order.add_tickets_from_params(@params, @boxoffice_user) }.to change { @order.ticket_count }.to(3)
      expect(@order.errors).to be_empty
    end
    it 'can add tickets beyond vouchertype sales limit' do
      @vv.update_attributes!(:max_sales_for_type => 2)
      expect { @order.add_tickets_from_params(@params, @boxoffice_user) }.to change { @order.ticket_count }.to(3)
      expect(@order.errors).to be_empty
    end
    it 'can add tickets for a date in the past' do
      Timecop.travel(@vv.showdate.thedate + 1.day) do
        expect { @order.add_tickets_from_params(@params, @boxoffice_user) }.to change { @order.ticket_count }.to(3)
        expect(@order.errors).to be_empty
      end
    end
  end
end
