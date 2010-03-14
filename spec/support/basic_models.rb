module BasicModels
  def self.create_customer_by_name_and_email(args)
      Customer.create!(:first_name => args[0],
      :last_name => args[1], :email => args[2],
      :role => (Customer.role_value(args[3] || :patron)))
  end
  def self.create_customer_by_role(role)
    c = Customer.create!(:first_name => "Joe",
      :last_name => "#{role}.to_s.capitalize")
    c.update_attribute(:role, Customer.role_value(role))
    c
  end
  def self.create_one_showdate(dt,cap=100)
    s = Show.create!(:name => "Show 1",
      :house_capacity => cap,
      :opening_date => dt - 1.week,
      :closing_date => dt + 1.week)
    sd = s.showdates.create!(:thedate => dt)
  end
end

      
