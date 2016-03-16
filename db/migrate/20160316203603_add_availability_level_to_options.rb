class AddAvailabilityLevelToOptions < ActiveRecord::Migration
  def self.up
    add_column :options, :limited_availability_threshold, :integer, :null => false, :default => 40
  end
end
