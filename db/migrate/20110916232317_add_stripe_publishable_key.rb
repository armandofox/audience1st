class AddStripePublishableKey < ActiveRecord::Migration
  require 'add_option_helper'
  def self.up
    AddOptionHelper.add_new_option(
      20, 'Config', 'stripe_publishable_key', '', :string)
    AddOptionHelper.add_new_option(
      21, 'Config', 'stripe_secret_key', '', :string)
    # and delete some obsolete options
    %w(monthly_fee cc_fee_markup per_ticket_fee per_ticket_commission customer_service_per_hour).each do |k|
      if (o = Option.find_by_name(k))
        o.destroy
      end
    end
  end

  def self.down
    Option.find_by_name('stripe_publishable_key').destroy
    Option.find_by_name('stripe_secret_key').destroy
  end
end
