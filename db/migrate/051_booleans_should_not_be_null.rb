class BooleansShouldNotBeNull < ActiveRecord::Migration
  def self.up
    [:customers, :e_blacklist,
      :customers, :blacklist,
      :customers, :is_current_subscriber,
      :vouchers, :changeable,
      :vouchers, :fulfillment_needed,
      :vouchers, :used,
      :vouchertypes, :walkup_sale_allowed,
      :vouchertypes, :fulfillment_needed].each_slice(2) do |t|
      change_column t[0], t[1], :boolean, :null => false, :default => nil
    end
  end

  def self.down
  end
end
