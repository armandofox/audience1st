class ShadowVouchers < ActiveRecord::Migration
  def change
    change_table :items do |t|
      t.boolean :finalized, :null => true, :default => nil
    end
    remove_column :items, :created_at
    add_index :items, :finalized
  end
end
