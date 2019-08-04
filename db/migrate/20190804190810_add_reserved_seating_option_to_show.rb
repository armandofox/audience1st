class AddReservedSeatingOptionToShow < ActiveRecord::Migration
  def change
    change_table 'shows' do |t|
      t.references :seatmap, :null => true, :default => nil
    end
  end
end
