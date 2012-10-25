Given /^a show "(.*)" with "(.*)" tickets for \$?(.*) on "(.*)"$/ do |show,type,price,date|
  Given %Q{a show "#{show}" with 100 "#{type}" tickets for $#{price} on "#{date}"}
end

Given /^a show "(.*)" with (\d+) "(.*)" tickets for \$(.*) on "(.*)"$/ do |show,num,type,price,date|
  Given %Q{a performance of "#{show}" on "#{date}"}
  Given %Q{#{num} #{type} vouchers costing $#{price} are available for that performance}
end

Given /^a show "(.*)" with the following tickets available:$/ do |show_name, tickets|
  tickets.hashes.each do |t|
    Given %Q{a show "#{show_name}" with #{t[:qty]} "#{t[:type]}" tickets for #{t[:price]} on "#{t[:showdate]}"}
  end
end

Given /^the following walkup tickets have been sold for "(.*)":$/ do |dt, tickets|
  showdate = Showdate.find_by_thedate!(Time.parse(dt))
  tickets.hashes.each do |t|
    qty = t[:qty].to_i
    offer = ValidVoucher.find_by_vouchertype_id_and_showdate_id!(
      Vouchertype.find_by_name!(t[:type]).id,
      showdate.id)
    vouchers = offer.sell!(qty, Customer.walkup_customer, Purchasemethod.find_by_shortdesc!(t[:payment]), Customer.boxoffice_daemon)
    vouchers.length.should == qty
  end
end

Then /^the cart should contain a donation of \$(.*) to "(.*)"$/ do |amount,account|
  # This should really check internal state of the cart, but due to current poor design
  #  that state's not externally grabbable because it's buried in the session.
  cart = controller.send(:find_cart)
  donation = cart.donations_only.first
  donation.should be_a_kind_of Donation
  donation.amount.should == amount
  donation.account_code.should == Account.find_by_name!(account)
end
