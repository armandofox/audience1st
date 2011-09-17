class AddStripePublishableKey < ActiveRecord::Migration
  def self.up
    opt = Option.create!(
      :grp => 'Config',
      :name => 'stripe_publishable_key',
      :value => '',
      :typ => :string)
    ActiveRecord::Base.connection.execute("UPDATE options SET id=20 WHERE id=#{opt.id}")
    # and delete some obsolete options
    %w(monthly_fee cc_fee_markup per_ticket_fee per_ticket_commission customer_service_per_hour).each do |k|
      if (o = Option.find_by_name(k))
        o.destroy
      end
    end
  end

  def self.down
    Option.find_by_name('stripe_publishable_key').destroy
  end
end
