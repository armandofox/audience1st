class AddBirthdayToCustomer < ActiveRecord::Migration
  def self.up
    add_column :customers, :birthday, :date, :null => true, :default => nil
    o = Option.create!(:grp => 'Email Notifications',
      :name => 'send_birthday_reminders',
      :value => '0',
      :typ => 'int')
    connection.execute("UPDATE options SET id=3007 WHERE id=#{o.id}")
  end

  def self.down
    remove_column :customers, :birthday
    connection.execute("DELETE FROM options WHERE name='send_birthday_reminders'")
  end
end
