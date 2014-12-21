require 'spec_helper'
describe Order do
  describe 'migrating to create order IDs' do
    before :each do
      sd = BasicModels.create_one_showdate(1.day.from_now)
      @v = Array.new(3) { BasicModels.new_voucher_for_showdate(sd,'Any') }
      @v.map(&:save!)
      @o = Order.create_from_existing_items! @v
    end
    it 'sets order ID' do
      @v.map(&:reload)
      @v.each { |v| v.order_id.should == @o.id }
    end
    it 'sets sold_on date' do
      @o.sold_on.should == @v.first.sold_on
      @o.sold_on.should_not be_nil
    end
  end
end


      
