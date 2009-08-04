class RemoveHouseCapacity < ActiveRecord::Migration
  def self.up
    add_column :showdates, :house_capacity, :integer, :null => false, :default => 0
    Showdate.find(:all, :include => :show).each do |s|
      s.update_attribute(:max_sales, s.show.house_capacity) if s.max_sales == 0
      s.update_attribute(:house_capacity, s.show.house_capacity)
    end
    remove_column :shows, :house_capacity
  end

  def self.down
    add_column :shows, :house_capacity, :integer, :null => false, :default => 0
    Shows.find(:all,:include => :showdates).each do |s|
      s.update_attribute(:house_capacity,
                         s.showdates.map { |sd| sd.house_capacity }.max)
    end
    remove_column :showdates, :house_capacity
  end
end
