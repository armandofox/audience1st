class CustomizeSeatingNeedsLanguage < ActiveRecord::Migration
  def change
    add_column :options, :accessible_seating_description, :string, :allow_nil => true, :default => 'Please describe (wheelchair, no stairs, etc.)'
  end
end
