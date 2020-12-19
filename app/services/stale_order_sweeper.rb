class StaleOrderSweeper
  # Deletes stale orders (abandoned and timeout has elapsed)
  # Because all of an order's Items are destroyed along with it, we only need to
  # operate on Orders, and ActiveRecord callbacks will take care of the rest.
  # There's only one class method, designed to be called from a periodic runner or similar.

  def self.sweep!
    # destroy stale orders and update sweep timer
    stale_date = (Option.order_timeout + 1).minutes.ago # just to be on the safe side
    Order.transaction do
      Order.abandoned_since(stale_date).destroy_all
      Option.first.update_attribute(:last_sweep, Time.current)
    end
  end
end
