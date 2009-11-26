World(FixtureAccess)

Given /^a performance (?:of "([^\"]+)" )?(?:at|on) (.*)$/i do |name,time|
  time = Time.parse(time)
  name ||= "New Show"
  show = Show.create!(:name => name,
                      :opening_date => Date.today,
                      :closing_date => Date.today)
  @showdate = show.showdates.create!(:thedate => time, :max_sales => 100)
end

Given /^today is (.*)$/i do |date|
  t = Time.parse(date)
  Time.stub!(:now).and_return(t)
  Date.stub!(:today).and_return(t)
end

Given /^(\d+ )?(.*) vouchers costing \$([0-9.]+) are available for this performance/i do |n,vouchertype,price|
  @showdate.should be_an_instance_of(Showdate)
  n = [n.to_i, 1].max           # in case n=0
  vt = Vouchertype.find_by_name!(vouchertype)
  vt.update_attribute(:price, price.to_f)
  @showdate.valid_vouchers.create!(:vouchertype => vt,
                                   :max_sales_for_type => n)
end
                                   
  
