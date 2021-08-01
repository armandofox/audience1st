class AddZonesToSeatmaps < ActiveRecord::Migration
  def change
    change_table :seatmaps, :force => true do |t|
      t.text :zones, :allow_nil => false, :default => {}.to_yaml
    end
  end
end
