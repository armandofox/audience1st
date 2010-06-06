class RemoveLogin < ActiveRecord::Migration
  def self.up
    # for all customers with login that looks like email addr but NO email field,
    # set email to  login field value
    Customer.connection.execute("UPDATE customers SET email=login WHERE (email IS NULL OR email='') AND (login LIKE '%@%')")
    # else, for customers with no email,
    # set created-by-admin to true, which allows having a null email field
    Customer.connection.execute("UPDATE customers SET created_by_admin=1 WHERE email IS NULL OR email=''")
    remove_column :customers, :login
  end

  def self.down
    add_column :customers, :login, :string, :null => true, :default => nil
  end
end
