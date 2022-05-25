class StaleOrderSweeper
  # Deletes stale orders (abandoned and timeout has elapsed)
  # Because all of an order's Items are destroyed along with it, we only need to
  # operate on Orders, and ActiveRecord callbacks will take care of the rest.
  # There's only one class method, designed to be called from a periodic runner or similar.

  def self.sweep!
    # destroy stale orders and update sweep timer
    stale_order_date = (Option.order_timeout + 1).minutes.ago # just to be on the safe side
    stale_import_date = (Option.import_timeout + 1).minutes.ago
    # first check for 'pending' CC orders and raise an alarm if any are found, since no
    # order should be 'pending' for more than a couple of seconds
    if (pending = Order.pending_but_paid.abandoned_since(2.minutes.ago))
      # mark those order(s) as errored
      pending.update_all(:authorization => Order::ERRORED)
    end
    ActiveRecord::Base.transaction do
      Order.where(:type => 'Order').abandoned_since(stale_order_date).destroy_all
      TicketSalesImport.abandoned_since(stale_import_date).destroy_all
      Option.first.update_attribute(:last_sweep, Time.current)
    end
  end
end
