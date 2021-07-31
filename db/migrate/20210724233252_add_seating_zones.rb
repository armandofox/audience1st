class AddSeatingZones < ActiveRecord::Migration
  def change
    create_table 'seating_zones', :force => true do |t|
      t.string :name, :allow_nil => false
      t.string :short_name, :allow_nil => false
    end
    SeatingZone.connection.schema_cache.clear!
    SeatingZone.reset_column_information
    SeatingZone.create!(name: 'Reserved', short_name: 'res')

    change_table :vouchertypes do |t|
      t.references :seating_zone, :null => true
    end
  end
end
