Given /^(\d+) "(.*)" vouchers have been issued$/ do |num, type|
  vt = Vouchertype.find_by_name(type) || FactoryBot.create(:vouchertype, :name => type)
  num.to_i.times { FactoryBot.create(:voucher, :vouchertype => vt) }
end

Then /the following "(.*)" tickets should have been imported for "(.*)":/ do |vtype,show,table|
  table.hashes.each do |h|
    steps %Q{Then customer "#{h['patron']}" should have #{h['qty']} "#{vtype}" tickets for "#{show}" on #{h['showdate']}}
  end
end

Then /^s?he should have ([0-9]+) "(.*)" tickets? for "(.*)" on (.*)$/ do |num,type,show,date|
  @showdate = Showdate.find_by_thedate!(Time.zone.parse(date))
  @showdate.show.name.should == show
  @vouchertype = Vouchertype.find_by_name!(type)
  expect(@customer.vouchers.where(:vouchertype_id => @vouchertype.id, :showdate_id => @showdate.id).count).
    to eq(num.to_i)
end

Then /^customer "(\S+) (.*)" should have the following vouchers?:$/ do |first,last,vouchers|
  @customer = find_customer first,last
  @vouchers = @customer.vouchers
  vouchers.hashes.each do |v|
    vtype = Vouchertype.find_by_name!(v[:vouchertype])
    found_vouchers = @vouchers.where('vouchertype_id = ?',vtype.id)
    found_vouchers.length.should == v[:quantity].to_i
    if v.has_key?(:showdate)
      if v[:showdate].blank?
        found_vouchers.all? { |v| v.showdate.should be_nil }.should be_truthy
      else
        date = Time.zone.parse v[:showdate]
        found_vouchers.all? { |v| v.showdate.thedate.should == date }.should be_truthy
      end
    end
  end
end


