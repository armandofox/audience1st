class AddOptionToAllowGuestCheckout < ActiveRecord::Migration
  def change
    add_column :options, :allow_guest_checkout, :boolean, :default => false
  end
end
