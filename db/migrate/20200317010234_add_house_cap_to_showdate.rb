class AddHouseCapToShowdate < ActiveRecord::Migration
  def change
    add_column :showdates, :house_capacity, :integer, :null => false, :default => 0
      Show.all.includes(:showdates).each do |show|
        cap = show.house_capacity
        show.showdates.update_all(:house_capacity => cap)
      end
    remove_column :shows, :house_capacity
  end
end
