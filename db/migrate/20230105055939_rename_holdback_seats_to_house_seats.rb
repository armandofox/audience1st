class RenameHoldbackSeatsToHouseSeats < ActiveRecord::Migration
  def change
    rename_column :showdates, :holdback_seats, :house_seats
  end
end
