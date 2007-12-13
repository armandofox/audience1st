class IsSubscriber < ActiveRecord::Migration
  def self.up
    raise "STOP! This migration isn't fully baked."
    add_column :customers, :is_subscriber_tmp,:boolean,:null=>true,:default=>false
    # reload model...
    subscribers = 0
    Customer.find(:all,:include=>:vouchers).each do |c|
      c.update_attribute(:is_subscriber_tmp, c.is_subscriber?)
    end
    rename_column :customers, :is_subscriber_tmp, :is_subscriber
  end

  def self.down
    remove_column :customers, :is_subscriber
  end
end
