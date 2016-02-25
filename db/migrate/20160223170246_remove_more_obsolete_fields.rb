class RemoveMoreObsoleteFields < ActiveRecord::Migration
  def self.up
    remove_column :vouchertypes, :promo_code
    remove_column :items, :no_show
  end

  def self.down
  end
end
