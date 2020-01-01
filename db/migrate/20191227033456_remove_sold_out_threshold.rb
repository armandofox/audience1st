class RemoveSoldOutThreshold < ActiveRecord::Migration
  def change
    remove_column :options, :sold_out_threshold
  end
end
