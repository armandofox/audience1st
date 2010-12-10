class AddTuningIndices < ActiveRecord::Migration
  @@indices = {
    'customers_labels' => :customer_id,
    'vouchers' => :showdate_id,
  }
  def self.up
    @@indices.each_pair {  |k,v|  add_index k, v  }
  end

  def self.down
    @@indices.each_pair {  |k,v|  remove_index k, v  }
  end
end
