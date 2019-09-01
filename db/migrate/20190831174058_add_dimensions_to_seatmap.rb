class AddDimensionsToSeatmap < ActiveRecord::Migration
  def change
    change_table 'seatmaps' do |t|
      t.integer :rows, :null => false, :default => 0
      t.integer :columns, :null => false, :default => 0
    end
    if (s = Seatmap.find_by(:name => 'Altarena default')) # data migration for Altarena default seatmap
      s.update_attributes!(:columns => 22, :rows => 16)
    end
  end
end
