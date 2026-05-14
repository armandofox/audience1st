class AddDatabaseConstraintUniqueSeat < ActiveRecord::Migration[6.1]
  # issue #183: add DB constraint to ensure unique seats
  def up
    add_index :items, [:showdate_id, :seat],
              unique: true,
              where: "type = 'Voucher' AND finalized = TRUE AND seat IS NOT NULL",
              name: "items_finalized_showdate_seat_unique"
  end

  def down
    remove_index :items, name: "items_finalized_showdate_seat_unique"
  end
end
