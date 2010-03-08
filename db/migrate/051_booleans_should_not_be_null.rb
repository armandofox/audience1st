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
      cmd = "UPDATE #{t[0]} SET #{t[1]}=0 WHERE #{t[1]} IS NULL"
      puts cmd
      ActiveRecord::Base.connection.execute(cmd)
      change_column t[0], t[1], :boolean, :null => false, :default => false
    end
  end

  def self.down
  end
end
