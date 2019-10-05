require 'rails_helper'

describe 'Order pre-purchase checks' do
  before :each do
    @order = create(:order)
    @vv = create(:valid_voucher)
    @order.add_tickets_without_capacity_checks(@vv, 2)
  end
  it 'should pass if all attributes valid' do
    expect(@order).to be_ready_for_purchase
    expect(@order.errors).to be_empty
  end
  def verify_error(regex)
    expect(@order).not_to be_ready_for_purchase
    expect(@order.errors.full_messages).to include_match_for(regex)
  end
  it 'should fail if no purchaser' do
    @order.purchaser = nil
    verify_error /No purchaser information/i
  end
  it 'should fail if purchaser invalid as purchaser' do
    allow(@order.purchaser).to receive(:valid_as_purchaser?).and_return(nil)
    allow(@order.purchaser).to receive_message_chain(:errors, :full_messages => ['ERROR'])
    verify_error /ERROR/
  end
  it 'should pass if purchaser invalid but order is placed by admin' do
    @order.processed_by = create(:customer, :role => :boxoffice)
    allow(@order.purchaser).to receive(:valid_as_purchaser?).and_return(nil)
    allow(@order.purchaser).to receive_message_chain(:errors, :full_messages => ['ERROR'])
    expect(@order).to be_ready_for_purchase
  end
  it 'should fail if no recipient' do
    @order.customer = nil
    verify_error /No recipient information/
  end
  it 'should fail if zero amount for purchasemethod other than cash' do
    allow(@order).to receive(:total_price).and_return(0.0)
    @order.purchasemethod = Purchasemethod.get_type_by_name('box_chk')
    verify_error /Zero amount/i
  end
  it 'should fail for credit card purchase with null token' do
    @order.purchasemethod = Purchasemethod.get_type_by_name('web_cc')
    @order.purchase_args = {:credit_card_token => nil}
    verify_error /Invalid credit card transaction/i
  end
  it 'should fail for credit card purchase with no token' do
    @order.purchasemethod = Purchasemethod.get_type_by_name('web_cc')
    @order.purchase_args = {}
    verify_error /Invalid credit card transaction/i
  end
  it 'should fail if recipient not a valid recipient' do
    allow(@order.customer).to receive(:valid_as_gift_recipient?).and_return(nil)
    allow(@order.customer).to receive_message_chain('errors.as_html').and_return(['Recipient error'])
    verify_error /Recipient error/
  end
  it 'should fail if no purchase method' do
    @order.purchasemethod = nil
    verify_error /No payment method specified/i
  end
  it 'should fail if no processed-by' do
    @order.processed_by = nil
    verify_error /No information on who processed/i
  end
  it 'should fail if contains a course enrollment without enrollee name' do
    @order.comments = nil
    allow(@order).to receive(:includes_enrollment?).and_return(true)
    verify_error /You must specify the enrollee's name for classes/ # '
  end
end
