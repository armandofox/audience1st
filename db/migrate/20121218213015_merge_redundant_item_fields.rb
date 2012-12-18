class MergeRedundantItemFields < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute "UPDATE items SET sold_on=date WHERE sold_on IS NULL and date IS NOT NULL"
    remove_column :items, :date
    ActiveRecord::Base.connection.execute "UPDATE items SET created_at=created_on"
    remove_column :items, :created_on
  end

  def self.down
  end
end
