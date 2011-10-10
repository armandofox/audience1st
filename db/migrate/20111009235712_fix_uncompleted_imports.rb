class FixUncompletedImports < ActiveRecord::Migration
  def self.up
    id = Customer.special_customer(:boxoffice_daemon).id
    ActiveRecord::Base.connection.execute "UPDATE imports SET customer_id=#{id},completed_at=updated_at   WHERE completed_at IS NULL AND number_of_records > 0"
  end

  def self.down
  end
end
