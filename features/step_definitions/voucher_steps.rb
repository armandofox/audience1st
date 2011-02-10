World(BasicModels)

Given /^customer (.*) (.*) has ([0-9]+) "(.*)" tickets$/ do |first,last,num,type|
  raise "No default showdate" unless @showdate.kind_of?(Showdate)
  c = BasicModels.create_generic_customer(:first_name => first, :last_name => last)
  1.upto(num.to_i) do
    c.vouchers << BasicModels.new_voucher_for_showdate(@showdate, type, :logged_in => c)
  end
end

Then /^customer (.*) (.*) should have ([0-9]+) "(.*)" tickets for "(.*)" on (.*)$/ do |first,last,num,type,show,date|
  (@customer = Customer.find_by_first_name_and_last_name(first,last)).should_not be_nil
  Then %Q{he should have #{num} "#{type}" tickets for "#{show}" on "#{date}"}
end

Then /^s?he should have ([0-9]+) "(.*)" tickets for "(.*)" on (.*)$/ do |num,type,show,date|
  (@showdate = Showdate.find_by_thedate(Time.parse date)).should_not be_nil
  @showdate.show.name.should == show
  (@vouchertype = Vouchertype.find_by_name(type)).should_not be_nil
  @customer.vouchers.find_all_by_vouchertype_id_and_showdate_id(@vouchertype.id,@showdate.id).length.should == num.to_i
end

Given /(?:an? )?"([^\"]+)" subscription available to (.*) for \$?([0-9.]+)/ do |name, to_whom, price| 
  @sub = Vouchertype.create!(
    :name => name,
    :price => price,
    :bundle_sales_start => Time.now - 1.day,
    :bundle_sales_end   => Time.now + 1.day,
    :walkup_sale_allowed => false,
    :offer_public => case to_whom
                 when /anyone/ ;     Vouchertype::ANYONE ;
                 when /subscriber/ ; Vouchertype::SUBSCRIBERS ;
                 when /external/ ;   Vouchertype::EXTERNAL ;
                 when /box ?office/ ;Vouchertype::BOXOFFICE ;
                 else raise "Subscription available to whom?"
                 end,
    :category => :bundle,
    :subscription => true,
    :account_code => AccountCode.default_account_code,
    :season => Time.this_season
    )
end

