Given /^customer (.*) (.*) has ([0-9]+) "(.*)" tickets$/ do |first,last,num,type|
  raise "No default showdate" unless @showdate.kind_of?(Showdate)
  customer = create(:customer, :first_name => first, :last_name => last)
  vtype = Vouchertype.find_by_name(type) || create(:revenue_vouchertype, :name => type)
  vv = ValidVoucher.find_by_vouchertype_id_and_showdate_id(vtype.id,@showdate.id) ||
    create(:valid_voucher, :vouchertype => vtype, :showdate => @showdate)
  order = create(:order,
    :purchasemethod => Purchasemethod.get_type_by_name('box_cash'),
    :customer => customer,
    :purchaser => customer)
  order.add_tickets_without_capacity_checks(vv, num.to_i)
  order.finalize!
end


Given /^customer "(\S+) (.*)" has (\d+) of (\d+) open subscriber vouchers for "(.*)"$/ do |first,last,num_free,num_total,show|
  c = find_or_create_customer first,last
  show = Show.find_by_name!(show)
  sub_vouchers = setup_subscriber_tickets(c, show, num_total)
  # reserve some of them?
  dummy_showdate = create(:showdate, :thedate => show.showdates.first.thedate + 1.day, :show => show)
  sub_vouchers[0, num_total.to_i - num_free.to_i].each { |v| v.reserve_for(dummy_showdate, Customer.boxoffice_daemon) }
end

Given /^customer "(\S+) (.*)" has (\d+) (non-)?cancelable subscriber reservations for (.*)$/ do |first,last,num,non,date|
  @customer = find_or_create_customer first,last
  @showdate = Showdate.find_by_thedate! Time.zone.parse(date) unless date =~ /that performance/
  sub_vouchers = setup_subscriber_tickets(@customer, @showdate.show, num, non.nil?)
  sub_vouchers.each { |v| v.reserve_for(@showdate, Customer.boxoffice_daemon) }
end

Then /^customer "(\S+) (.*)" should have the following items:$/ do |first,last,items|
  @customer = find_customer first,last
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
    expect(Item.where(conds_clause,*conds_values).first).not_to be_nil
  end
end


Then /^customer "(.*) (.*)" should (not )?have a donation of \$([0-9.]+) to "(.*?)"(?: with comment "(.*)")?$/ do |first,last,no,amount,fund,comment|
  fund_id = AccountCode.find_by(:name => fund).id
  result = Customer.find_by(:first_name => first, :last_name => last).donations.any? do |d|
    d.amount == amount.to_f
    d.account_code_id = fund_id
    comment.nil? || d.comments == comment
  end
  no ? !result : result
end

Then /^customer "(\S+) (.*)" should have the following vouchers?:$/ do |first,last,vouchers|
  @customer = find_customer first,last
  @vouchers = @customer.vouchers
  vouchers.hashes.each do |v|
    vtype = Vouchertype.find_by_name!(v[:vouchertype])
    found_vouchers = @vouchers.where('vouchertype_id = ?',vtype.id)
    expect(found_vouchers.length).to eq(v[:quantity].to_i)
    if v.has_key?(:showdate)
      if v[:showdate].blank?
        found_vouchers.all? { |v| expect(v.showdate).to be_nil }.should be_truthy
      else
        date = Time.zone.parse v[:showdate]
        found_vouchers.all? { |v| expect(v.showdate.thedate).to eq(date) }.should be_truthy
      end
    end
  end
end

Then /^customer "(\S+) (.*)" should have ([0-9]+) "(.*)" tickets? for "(.*)" on (.*)$/ do |first,last,num,type,show,date|
  @customer = find_customer first,last
  steps %Q{Then he should have #{num} "#{type}" tickets for "#{show}" on "#{date}"}
end

Then /^s?he should have ([0-9]+) "(.*)" tickets? for "(.*)" on (.*)$/ do |num,type,show,date|
  @showdate = Showdate.find_by_thedate!(Time.zone.parse(date))
  expect(@showdate.show.name).to eq(show)
  @vouchertype = Vouchertype.find_by_name!(type)
  expect(@customer.vouchers.where(:vouchertype_id => @vouchertype.id, :showdate_id => @showdate.id).count).
    to eq(num.to_i)
end

Then /^customer "(.*) (.*)" should have an order (with comment "(.*)" )?containing the following tickets:$/ do |first,last,comments,table|
  @customer = find_customer(first,last)
  order = @customer.orders.first
  order.comments.should == comments
  table.hashes.each do |item|
    matching_items = order.vouchers.select { |v| v.vouchertype.name == item['type'] }
    unless item['showdate'].blank?
      matching_items.reject! { |v| v.showdate != Showdate.find_by_thedate(Time.zone.parse(item['showdate'])) }
    end
    matching_items.length.should == item['qty'].to_i
  end
end

Then /the following "(.*)" tickets should have been imported for "(.*)":/ do |vtype,show,table|
  table.hashes.each do |h|
    steps %Q{Then customer "#{h['patron']}" should have #{h['qty']} "#{vtype}" tickets for "#{show}" on #{h['showdate']}}
  end
end

