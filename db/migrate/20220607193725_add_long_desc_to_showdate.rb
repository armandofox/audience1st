class AddLongDescToShowdate < ActiveRecord::Migration
  def change
    add_column :showdates, :long_description, :text, :null => true, :default => nil
  end
end
