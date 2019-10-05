require 'rails_helper'

describe ImportableOrder do
  describe 'finalizing' do
    before(:each) do
      @i = ImportableOrder.new
      @v = create(:valid_voucher)
      @i.order.add_tickets_without_capacity_checks(@v, 2)
      @i.order.purchaser
    end
    it 'sets sold_on to original sale date'
    it 'copies comment to 1 item in the order'
    it 'copies order number to Order external_key'
  end
end
