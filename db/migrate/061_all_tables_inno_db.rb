class AllTablesInnoDb < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE donation_funds ENGINE=InnoDB"
    execute "ALTER TABLE vouchertypes ENGINE=InnoDB"
  end
  def self.down
  end
end
