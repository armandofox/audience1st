class Checkin < ActiveRecord::Migration
  def self.up
    rename_column 'vouchers', 'used', 'checked_in'
    connection.execute("UPDATE vouchers v JOIN showdates s ON v.showdate_id=s.id SET v.checked_in=1 WHERE s.thedate <= '#{Time.now.to_formatted_s(:db)}'")
  end

  def self.down
    rename_column 'vouchers', 'checked_in', 'used'
  end
end
