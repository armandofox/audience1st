Given /^(\d+) "(.*)" comps are available for "(.*)" on "([^\"]+)"(?: with promo code "(.*)")?$/ do |num,comp_type,show_name,date,code|
  show_date = Time.zone.parse(date)
  @showdate = setup_show_and_showdate(show_name,show_date)
  @comp = Vouchertype.find_by(:name => comp_type) || create(:comp_vouchertype, :name => comp_type, :season => show_date.year)
  @comp.update_attributes!(:offer_public => Vouchertype::ANYONE) if code
  make_valid_tickets(@showdate, @comp, num, code)
end

Given /an advance sales limit of (\d+) for the (.*) performance/ do |limit,thedate|
  @showdate = Showdate.find_by!(:thedate => Time.zone.parse(thedate))
  @showdate.update_attributes!(:max_advance_sales => limit)
end

Given /^a show "(.*)" with the following tickets available:$/ do |show_name, tickets|
  tickets.hashes.each do |t|
    steps %Q{Given a show "#{show_name}" with #{t[:qty]} "#{t[:type]}" tickets for #{t[:price]} on "#{t[:showdate]}"}
    # if sales cutoff time is specified, modify the valid-voucher once created
    if (cutoff = t[:sales_cutoff])
      sd = Showdate.find_by!(:thedate => Time.parse(t[:showdate]))
      vv = ValidVoucher.find_by!(:showdate => sd, :vouchertype => Vouchertype.find_by!(:name => t[:type]))
      vv.update_attributes(:end_sales => sd.thedate - cutoff.to_i.minutes)
    end
  end
end

Given /^a show "(.*)" with (\d+) "(.*)" tickets for \$(.*) on "(.*)"$/ do |show,num,type,price,date|
  steps %Q{Given a performance of "#{show}" on "#{date}"
           And #{num} #{type} vouchers costing $#{price} are available for that performance}
end

Given /^(\d+ )?(.*) vouchers costing \$([0-9.]+) are available for (?:this|that) performance/i do |n,vouchertype,price|
  @showdate.should be_an_instance_of(Showdate)
  steps %Q{Given a "#{vouchertype}" vouchertype costing $#{price} for the #{@showdate.season} season}
  make_valid_tickets(@showdate, @vouchertype, n.to_i)
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
  order = create(:order, :walkup => true, :processed_by => Customer.boxoffice_daemon)
  qty = qty.to_i
  showdate = Showdate.find_by_thedate!(Time.zone.parse(dt))
  offer = ValidVoucher.find_by_vouchertype_id_and_showdate_id!(
    Vouchertype.find_by_name!(vtype).id,
    showdate.id)
  order.add_tickets_without_capacity_checks(offer, qty)
  order.finalize!
end

Given /"(.*)" for \$?([0-9.]+) is available (at checkin )?for all performances of "(.*)"/ do |item,price,walkup,show|
  price = price.to_f
  showdates = Show.find_by!(:name => show).showdates
  vtype = Vouchertype.find_by(:name => item, :price => price, :category => 'nonticket') ||
    create(:vouchertype, :walkup_sale_allowed => (!walkup.blank?), :name => item, :price => price, :category => 'nonticket')
  showdates.each do |date|
    create(:valid_voucher, :showdate => date, :vouchertype => vtype)
  end
end

Given /the "(.*)" redemption for "(.*)" ends sales at "(.*)"/ do |vtype_name, showdate_s, end_sales_s|
  vouchertype = Vouchertype.find_by!(:name => vtype_name)
  showdate = Showdate.find_by!(:thedate => Time.zone.parse(showdate_s))
  new_end_sales = Time.zone.parse(end_sales_s)
  ValidVoucher.find_by!(:showdate => showdate, :vouchertype => vouchertype).update_attributes!(:end_sales => new_end_sales)
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
