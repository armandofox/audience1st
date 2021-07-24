class AddSeatingZones < ActiveRecord::Migration
  def change
    create_table 'seating_zones', :force => true do |t|
      t.string :name, :allow_nil => false
      t.string :short_name, :allow_nil => false
    end
    SeatingZone.connection.schema_cache.clear!
    SeatingZone.reset_column_information
    SeatingZone.create!(name: 'Reserved', short_name: 'r')
    SeatingZone.create!(name: 'Premium', short_name: 'p')

    change_table :vouchertypes do |t|
      t.references :seating_zone_id, :null => true
    end
  end
end
