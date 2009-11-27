class RemoveHouseCapacity < ActiveRecord::Migration
  def self.up
    Showdate.find(:all, :include => :show).each do |s|
      s.update_attribute(:max_sales, s.show.house_capacity) if s.max_sales == 0
    end
  end

  def self.down
  end
end
