Given /^customer (.*) (.*) has ([0-9]+) "(.*)" tickets$/ do |first,last,num,type|
  raise "No default showdate" unless @showdate.kind_of?(Showdate)
  customer = create(:customer, :first_name => first, :last_name => last)
  vtype = Vouchertype.find_by_name(type) || create(:revenue_vouchertype, :name => type)
  vv = ValidVoucher.find_by_vouchertype_id_and_showdate_id(vtype.id,@showdate.id) ||
    create(:valid_voucher, :vouchertype => vtype, :showdate => @showdate)
  order = build(:order,
    :purchasemethod => Purchasemethod.get_type_by_name('box_cash'),
    :customer => customer,
    :purchaser => customer)
  order.add_tickets(vv, num.to_i)
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
    Item.where(conds_clause,*conds_values).first.should_not be_nil
  end
end


Then /^customer "(\S+) (.*)" should have ([0-9]+) "(.*)" tickets? for "(.*)" on (.*)$/ do |first,last,num,type,show,date|
  @customer = find_customer first,last
  steps %Q{Then he should have #{num} "#{type}" tickets for "#{show}" on "#{date}"}
end

