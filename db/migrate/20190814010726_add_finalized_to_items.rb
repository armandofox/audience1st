class AddFinalizedToItems < ActiveRecord::Migration
  def change
    add_column :items, :finalized, :boolean, :null => true, :default => nil
    Item.update_all :finalized => true
  end
end
