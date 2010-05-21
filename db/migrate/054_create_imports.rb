class CreateImports < ActiveRecord::Migration
  def self.up
    create_table :imports do |t|
      t.string :name
      t.boolean :completed
      t.string :type
      t.integer :number_of_records
      t.string :filename
      t.string :content_type
      t.integer :size
      t.timestamps
    end
  end

  def self.down
    drop_table :imports
  end
end
