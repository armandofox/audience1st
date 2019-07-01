Given /^(\d+ )?(.*) vouchers costing \$([0-9.]+) are available for (?:this|that) performance/i do |n,vouchertype,price|
  @showdate.should be_an_instance_of(Showdate)
  steps %Q{Given a "#{vouchertype}" vouchertype costing $#{price} for the #{@showdate.season} season}
  make_valid_tickets(@showdate, @vouchertype, n.to_i)
end

Given /^(\d+) "(.*)" comps are available for "(.*)" on "([^\"]+)"(?: with promo code "(.*)")?$/ do |num,comp_type,show_name,date,code|
  show_date = Time.zone.parse(date)
  @showdate = setup_show_and_showdate(show_name,show_date)
  @comp = create(:comp_vouchertype, :name => comp_type, :season => show_date.year)
  @comp.update_attributes!(:offer_public => Vouchertype::ANYONE) if code
  make_valid_tickets(@showdate, @comp, num, code)
end
                                   
Given /^a show "(.*)" with the following tickets available:$/ do |show_name, tickets|
  tickets.hashes.each do |t|
    steps %Q{Given a show "#{show_name}" with #{t[:qty]} "#{t[:type]}" tickets for #{t[:price]} on "#{t[:showdate]}"}
  end
end

Given /^a show "(.*)" with "(.*)" tickets for \$?(.*) on "(.*)"$/ do |show,type,price,date|
  steps %Q{Given a show "#{show}" with 100 "#{type}" tickets for $#{price} on "#{date}"}
end

Given /^a show "(.*)" with (\d+) "(.*)" tickets for \$(.*) on "(.*)"$/ do |show,num,type,price,date|
  steps %Q{Given a performance of "#{show}" on "#{date}"
           And #{num} #{type} vouchers costing $#{price} are available for that performance}
end

Given /^the "(.*)" tickets for "(.*)" require promo code "(.*)"$/ do |ticket_type,date,promo|
  vouchertype = Vouchertype.find_by_name! ticket_type
  showdate = Showdate.find_by_thedate! Time.zone.parse date
  ValidVoucher.find_by_vouchertype_id_and_showdate_id(vouchertype.id, showdate.id).
    update_attributes!(:promo_code => promo)
end

Given /^the following walkup tickets have been sold for "(.*)":$/ do |dt, tickets|
  tickets.hashes.each do |t|
    qty = t[:qty].to_i
    steps %Q{Given #{t[:qty]} "#{t[:type]}" tickets have been sold for "#{dt}"}
  end
end

Given /^(\d+) "(.*)" tickets? have been sold for "(.*)"$/ do |qty,vtype,dt|
  order = build(:order, :walkup => true, :processed_by => Customer.boxoffice_daemon)
  qty = qty.to_i
  showdate = Showdate.find_by_thedate!(Time.zone.parse(dt))
  offer = ValidVoucher.find_by_vouchertype_id_and_showdate_id!(
    Vouchertype.find_by_name!(vtype).id,
    showdate.id)
  order.add_tickets(offer, qty)
  order.finalize!
end


Then /^ticket sales should be as follows:$/ do |tickets|
  tickets.hashes.each do |t|
    steps %Q{Then there should be #{t[:qty]} "#{t[:type]}" tickets sold for "#{t[:showdate]}"}
  end
end

Then /^there should be (\d+) "(.*)" tickets? sold for "(.*)"$/ do |qty,vtype_name,date|
  vtype = Vouchertype.find_by_name!(vtype_name)
  showdate = Showdate.find_by_thedate!(Time.zone.parse(date))
  showdate.vouchers.where('vouchertype_id = ?', vtype.id).count.should == qty.to_i
end
