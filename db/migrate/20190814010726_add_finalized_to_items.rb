class AddFinalizedToItems < ActiveRecord::Migration
  def change
    add_column :items, :finalized, :boolean, :null => true, :default => nil
    add_index :items, :finalized
    Item.update_all :finalized => true

    add_column :items, :seat, :string, :null => true, :default => nil
    add_index :items, :seat
    
  end
end
