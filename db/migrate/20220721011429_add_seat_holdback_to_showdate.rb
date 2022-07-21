class AddSeatHoldbackToShowdate < ActiveRecord::Migration
  def change
    change_table :showdates do |t|
      t.string :holdback_seats, :null => true, :default => nil, :limit => 8192
    end
  end
end
