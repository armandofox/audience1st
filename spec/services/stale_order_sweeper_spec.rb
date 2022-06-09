describe StaleOrderSweeper do

  describe 'abandoned orders'  do
    before(:each) do
      @old_order = create(:order)
      @old_id = old_order.id
    end
    specify 'are swept if too old' do
      @old_order.update_attribute(:updated_at, 1.day.ago)
      StaleOrderSweeper.sweep_abandoned_orders_and_imports
      expect(Order.find_by(:id => @old_id)).to be_nil
    end
    specify 'are not swept if within abandon threshold' do
      Option.first.update_attribute(:stale_order_timeout, 10) # minutes
      StaleOrderSweeper.sweep_abandoned_orders_and_imports
      expect(Order.find_by(:id => @old_id)).to eq(@old_order)
    end
  end

  describe 'when an order has failed', focus: true do
    before(:each) do
      @o = create(:order)
      @o.update_attribute(:authorization, Order::PENDING)
      @o.update_attribute(:updated_at, 3.minutes.ago)
    end
    it 'notifies of error' do
      expect(NewRelic::Agent).to receive(:notice_error)
      StaleOrderSweeper.notice_failed_orders!
    end
    it 'changes order status to errored' do
      StaleOrderSweeper.notice_failed_orders!
      expect(@o.reload.authorization).to eq(Order::ERRORED)
    end
  end
end
