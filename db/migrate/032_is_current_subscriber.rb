class IsCurrentSubscriber < ActiveRecord::Migration
  def self.up
    add_column :customers, :is_current_subscriber,:boolean,:null=>true,:default=>false
    ActiveRecord::Base.connection.execute <<EOQ1
 UPDATE customers c,vouchers v,vouchertypes vt 
 SET c.is_current_subscriber = 1 
 WHERE v.customer_id = c.id AND v.vouchertype_id=vt.id
    AND vt.id IN (55,56,57,58,62)
EOQ1
  end

  def self.down
    remove_column :customers, :is_current_subscriber
  end
end
