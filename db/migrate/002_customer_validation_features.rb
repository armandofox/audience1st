class CustomerValidationFeatures < ActiveRecord::Migration
  def self.up
    add_column :customers, :blacklist, :boolean, :default => false
    add_column :customers, :validation_level, :integer, :default => 0
    execute 'UPDATE customers SET validation_level=1 WHERE street != ""'
  end

  def self.down
    remove_column :customers, :blacklist
    remove_column :customers, :validation_level
  end
end
