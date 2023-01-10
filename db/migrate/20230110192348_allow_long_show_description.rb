class AllowLongShowDescription < ActiveRecord::Migration
  def change
    change_column :shows, :description, :text, :null => true, :default => nil
  end
end
