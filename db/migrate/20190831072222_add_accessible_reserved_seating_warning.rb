class AddAccessibleReservedSeatingWarning < ActiveRecord::Migration
  def change
    change_table 'options' do |t|
      t.text 'accessibility_advisory_for_reserved_seating', null: false, default: 'This seat is designated as an accessible seat.  Please ensure you need this accommodation before finalizing this reservation.'
    end
  end
end
