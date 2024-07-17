class CustomizeSeatingNeedsLanguage < ActiveRecord::Migration
  def change
    add_column :options, :accessibility_needs_prompt, :string, :allow_nil => true, :default => 'Please describe (wheelchair, no stairs, etc.)'
  end
end
