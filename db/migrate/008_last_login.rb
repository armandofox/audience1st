class LastLogin < ActiveRecord::Migration
  def self.up
    # add last-login field, initialize to today
    now = Time.now
    change_column :customers, :login, :string, :null => true, :default => nil
    Customer.update_all("login = NULL", "login = ''")
    add_column :customers, :last_login, :datetime, :null => false, :default => now
    add_column :vouchers, :no_show, :boolean, :null => false, :default => false
    # fix possible problem wherein "walkup customer" and "walkup sales"
    # have the same login (which must be unique)
  end

  def self.down
    remove_column :customers, :last_login
    remove_column :vouchers, :no_show
    change_column :customers, :login, :null => false, :default => ''
  end
end
