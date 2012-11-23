class CustomCheckoutMessage < ActiveRecord::Migration
  def self.up
    newopt = Option.create!(:grp => 'Customer Notices', :name => 'precheckout_popup', :typ => :text, :value => "PLEASE DOUBLE CHECK DATES before submitting your order.  If they're not correct, you will be able to Cancel before placing the order.")
    ActiveRecord::Base.connection.execute("UPDATE options SET id=3502 WHERE id=#{newopt.id}")
  end

  def self.down
  end
end
