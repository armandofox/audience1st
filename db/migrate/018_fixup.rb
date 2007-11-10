class Fixup < ActiveRecord::Migration
  def self.up
    # need ALTER TABLE statements to set default Null values...see
    # documentation for change_column
    %w[login street city zip day_phone eve_phone].each do |c|
      Customer.connection.execute("ALTER TABLE customers MODIFY #{c} varchar(255) default NULL;")
    end
    Donation.connection.execute("ALTER TABLE donations MODIFY comment varchar(255) default NULL;")
  end

  def self.down
  end
end
