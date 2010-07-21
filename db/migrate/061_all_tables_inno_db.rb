class AllTablesInnoDb < ActiveRecord::Migration
  def self.up
    schema = []
    select_all('SHOW TABLES').inject([]) do |schema, table|
      schema << "ALTER TABLE #{table.to_a.first.last} ENGINE=InnoDB"
    end
    schema.each { |line| execute line }
  end
  def self.down
  end
end
