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
    c.update_attributes!({:role => (Customer.role_value(args[3] || :patron))})
    c
  end
  def self.create_customer_by_role(role,args={})
    c = self.create_generic_customer(args)
    c.update_attribute(:role, Customer.role_value(role))
    c
  end
  def self.create_one_showdate(dt,cap=100,s=nil,name="Show 1")
    s ||= Show.create!(:name => name,
      :house_capacity => cap,
      :opening_date => dt - 1.week,
      :closing_date => dt + 1.week)
    sd = s.showdates.create!(:thedate => dt,
      :end_advance_sales => dt - 1.minute)
  end
  def self.create_comp_vouchertype(args={})
    Vouchertype.create!({:fulfillment_needed => false,
        :name => 'comp voucher',
        :category => 'comp',
        :price => 0,
        :season => Time.now.year
        }.merge(args))
  end
  def self.create_nonticket_vouchertype(args={})
    Vouchertype.create!({:fulfillment_needed => false,
      :name => 'nonticket product',
      :category => 'nonticket',
      :account_code => AccountCode.default_account_code,
      :price => 10.00,
      :season => Time.now.year}.merge(args))
  end
  def self.create_revenue_vouchertype(args={})
    Vouchertype.create!({:fulfillment_needed => false,
      :name => 'regular voucher',
      :category => 'revenue',
      :account_code => AccountCode.default_account_code,
      :price => 10.00,
      :season => Time.now.year}.merge(args))
  end
  def self.create_subscriber_vouchertype(args={})
    sym = self.gensym
    Vouchertype.create!({:fulfillment_needed => false,
      :name => 'subscription #{sym}',
        :category => 'bundle',
      :subscription => true,
      :account_code => AccountCode.default_account_code,
      :price => 20.00,
      :season => Time.now.year}.merge(args))
  end
  def self.create_bundle_vouchertype(args={})
    Vouchertype.create!({:fulfillment_needed => false,
        :name => "Bundle",
        :category => 'bundle',
        :offer_public => Vouchertype::ANYONE,
        :bundle_sales_start => 1.week.ago,
        :bundle_sales_end => 1.week.from_now,
        :subscription => false,
        :account_code => AccountCode.default_account_code,
        :price => 20.00,
        :season => Time.now.year}.merge(args))
  end
  def self.create_included_vouchertype(args={})
    Vouchertype.create!({:fulfillment_needed => false,
        :name => self.gensym,
        :category => 'subscriber',
        :price => 0,
        :season => Time.now.year}.merge(args))
  end
  def self.create_generic_show(name="Some Show",opts={})
    Show.create!({
      :name => name,
      :house_capacity => 1,
      :opening_date => Date.today,
      :closing_date => Date.today + 1.day,
        :listing_date => Date.today}.merge(opts))
  end

  def self.new_voucher_for_showdate(showdate, vtype, opts={})
    vt = vtype.kind_of?(Vouchertype) ? vtype :
      (Vouchertype.find_by_name(vtype) || self.create_revenue_vouchertype(:name => vtype))
    Voucher.new_from_vouchertype(vt).reserve(showdate,
      (opts[:logged_in] || self.create_generic_customer(:created_by_admin => true, :role => 100, :first_name => 'MockBoxOfficeManager')))
  end
end

      
