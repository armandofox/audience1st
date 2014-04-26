World(BasicModels)

Given /^customer (.*) (.*) has ([0-9]+) "(.*)" tickets$/ do |first,last,num,type|
  raise "No default showdate" unless @showdate.kind_of?(Showdate)
  c = BasicModels.create_generic_customer(:first_name => first, :last_name => last)
  1.upto(num.to_i) do
    c.vouchers << BasicModels.new_voucher_for_showdate(@showdate, type, :logged_in => c)
  end
end

Then /^customer (.*) (.*) should have the following items:$/ do |first,last,items|
  @customer = Customer.find_by_first_name_and_last_name!(first,last)
  items.hashes.each do |item|
    conds_clause = 'type = ? AND amount BETWEEN ? AND ?  AND customer_id = ?'
    conds_values = [item[:type], item[:amount].to_f-0.01, item[:amount].to_f+0.01, @customer.id]
    if !item[:comments].blank?
      conds_clause << ' AND comments = ?'
      conds_values << item[:comments]
    end 
    if !item[:account_code].blank?
      conds_clause << ' AND account_code_id = ?'
      conds_values << AccountCode.find_by_code!(item[:account_code]).id
    end
    Item.find(:first, :conditions => [conds_clause] + conds_values).should_not be_nil
  end
end

Then /^customer (.*) (.*) should have ([0-9]+) "(.*)" tickets for "(.*)" on (.*)$/ do |first,last,num,type,show,date|
  @customer = Customer.find_by_first_name_and_last_name!(first,last)
  steps %Q{Then he should have #{num} "#{type}" tickets for "#{show}" on "#{date}"}
end

Then /^s?he should have ([0-9]+) "(.*)" tickets for "(.*)" on (.*)$/ do |num,type,show,date|
  @showdate = Showdate.find_by_thedate!(Time.parse(date))
  @showdate.show.name.should == show
  @vouchertype = Vouchertype.find_by_name!(type)
  puts debugger
  @customer.vouchers.count(
    :conditions => ['vouchertype_id = ? AND showdate_id = ?', @vouchertype.id,@showdate.id]).
    should == num.to_i
end

Then /^customer (.*) (.*) should have the following vouchers:$/ do |first,last,vouchers|
  @customer = Customer.find_by_first_name_and_last_name!(first,last)
  @vouchers = @customer.vouchers
  puts debugger
  vouchers.hashes.each do |v|
    vtype = Vouchertype.find_by_name!(v[:vouchertype])
    found_vouchers = @vouchers.find_all_by_vouchertype_id(vtype.id)
    found_vouchers.length.should == v[:quantity].to_i
    if v.has_key(:showdate)
      if v[:showdate].blank?
        found_vouchers.all? { |v| v.showdate.should be_nil }.should be_true
      else
        date = Time.parse v[:showdate]
        found_vouchers.all? { |v| v.showdate.thedate.should == date }.should be_true
      end
    end
  end
end

Then /^there should be (\d+) "(.*)" tickets sold for "(.*)"$/ do |qty,vtype_name,date|
  vtype = Vouchertype.find_by_name!(vtype_name)
  showdate = Showdate.find_by_thedate!(Time.parse(date))
  showdate.vouchers.count(:conditions => ['vouchertype_id = ?', vtype.id]).should == qty.to_i
end

Then /^ticket sales should be as follows:$/ do |tickets|
  tickets.hashes.each do |t|
    steps %Q{Then there should be #{t[:qty]} "#{t[:type]}" tickets sold for "#{t[:showdate]}"}
  end
end

Given /(?:an? )?"([^\"]+)" subscription available to (.*) for \$?([0-9.]+)/ do |name, to_whom, price| # "
  @sub = Vouchertype.create!(
    :name => name,
    :category => :bundle,
    :subscription => true,
    :price => price,
    :walkup_sale_allowed => false,
    :offer_public => case to_whom
                 when /anyone/ ;     Vouchertype::ANYONE ;
                 when /subscriber/ ; Vouchertype::SUBSCRIBERS ;
                 when /external/ ;   Vouchertype::EXTERNAL ;
                 when /box ?office/ ;Vouchertype::BOXOFFICE ;
                 else raise "Subscription available to whom?"
                 end,
    :account_code => AccountCode.default_account_code,
    :season => Time.now.at_beginning_of_season.year
    )
  @sub.valid_vouchers.first.update_attributes!(
    :start_sales => Time.now.at_beginning_of_season,
    :end_sales   => Time.now.at_end_of_season,
    :max_sales_for_type => nil
    )
end

Given /^the "(.*)" subscription includes the following vouchers:/ do |name, vouchers|
  sub = Vouchertype.find_by_category_and_name!(:bundle, name)
  sub.included_vouchers ||= {}
  vouchers.hashes.each do |voucher|
    vt = BasicModels.create_included_vouchertype(:name => "#{voucher[:name]} (subscriber)")
    sub.included_vouchers[vt.id] = voucher[:quantity]
  end
  sub.save!
end
