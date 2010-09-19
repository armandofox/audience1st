module BasicModels
  @@id = 2001
  def self.gensym
    @@id += 1
    @@id.to_s
  end
  def self.new_generic_customer_params(args={})
    sym = self.gensym
    {:first_name => "Joe#{sym}",
      :last_name => "Doe#{sym}",
      :email => "joe#{sym}@yahoo.com",
      :password =>  'xxxxx', :password_confirmation => 'xxxxx',
      :day_phone => "212-555-5555",
      :street => "123 Fake St",
      :city => "New York",
      :state => "NY",
        :zip => "10019"
    }.merge(args)
  end
  def self.new_generic_customer(args={})
    Customer.new(self.new_generic_customer_params(args))
  end
  def self.create_generic_customer(args={})
    c = self.new_generic_customer(args)
    c.created_by_admin = true if args[:created_by_admin]
    c.save!
    c
  end
  def self.create_customer_by_name_and_email(args)
    c = Customer.create!(:first_name => args[0],
      :last_name => args[1], :email => args[2],
      :password => 'pass', :password_confirmation => 'pass'
      )
    c.update_attributes!({:role, (Customer.role_value(args[3] || :patron))})
    c
  end
  def self.create_customer_by_role(role,args={})
    c = self.create_generic_customer(args)
    c.update_attribute(:role, Customer.role_value(role))
    c
  end
  def self.create_one_showdate(dt,cap=100)
    s = Show.create!(:name => "Show 1",
      :house_capacity => cap,
      :opening_date => dt - 1.week,
      :closing_date => dt + 1.week)
    sd = s.showdates.create!(:thedate => dt,
      :end_advance_sales => dt - 1.minute)
  end
  def self.create_revenue_vouchertype()
    Vouchertype.create!(:fulfillment_needed => false,
      :name => 'regular voucher',
      :category => 'revenue',
      :account_code => '9999',
      :price => 10.00,
      :valid_date => Time.now - 1.month,
      :expiration_date => Time.now+1.month)
  end
  def self.create_subscriber_vouchertype()
    sym = self.gensym
    Vouchertype.create!(:fulfillment_needed => false,
      :name => 'subscription #{sym}',
      :category => 'bundle',
      :subscription => true,
      :account_code => '9999',
      :price => 20.00,
      :valid_date => Time.now - 1.month,
      :expiration_date => Time.now - 1.month + 1.year)
  end
      
  def self.create_generic_show(name="Some Show",opts={})
    Show.create!({
      :name => name,
      :house_capacity => 1,
      :opening_date => Date.today,
      :closing_date => Date.today + 1.day,
        :listing_date => Date.today}.merge(opts))
  end

end

      
