class StaleOrderSweeper
  # Deletes stale orders (abandoned and timeout has elapsed)
  # Because all of an order's Items are destroyed along with it, we only need to
  # operate on Orders, and ActiveRecord callbacks will take care of the rest.
  # There's only one class method, designed to be called from a periodic runner or similar.

  def self.sweep!
    # raise error for orders where CC charge & order proc didn't happen atomically
    self.notice_failed_orders!
    # destroy stale (customer-abandoned) orders and update sweep timer
    self.sweep_abandoned_orders_and_imports
  end

  def self.notice_failed_orders!
    # first check for 'pending' CC orders and raise an alarm if any are found, since no
    # order should ever be 'pending' for more than a few seconds
    unless (pending = Order.pending_but_paid.abandoned_since(2.minutes.ago)).empty?
      # raise a flare
      stale_order_err = Order::StaleOrderError.new("Stale order ids: #{pending.map(&:id).join(',')}")
      if defined?(NewRelic)
        NewRelic::Agent.notice_error(stale_order_err)
      end
      
      # mark those order(s) as errored, so they don't trigger the warning again
      pending.update_all(:authorization => Order::ERRORED)
    end
  end

  def self.sweep_abandoned_orders_and_imports
    stale_order_date = (Option.order_timeout + 1).minutes.ago # just to be on the safe side
    stale_import_date = (Option.import_timeout + 1).minutes.ago
    ActiveRecord::Base.transaction do
      Order.where(:type => 'Order').abandoned_since(stale_order_date).destroy_all
      TicketSalesImport.abandoned_since(stale_import_date).destroy_all
      Option.first.update_attribute(:last_sweep, Time.current)
    end
  end

end
