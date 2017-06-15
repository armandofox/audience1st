Given /^an order for customer "(.*)" paid with "credit card" containing:$/ do |customer, table|
  step %Q{I am logged in as customer "#{customer}"}
  step(%Q{my cart contains the following tickets:}, table)
  step %Q{I place my order with a valid credit card}
end

Given /^that order has the comment "(.*)"$/ do |comment|
  @order.update_attributes!(:comments => comment)
end

Then /^I should see the following details for that order:$/ do |table|
  within("div#details_order_#{@order.id}") do
    table.hashes.each do |h|
      page.should have_content h[:content]
    end
  end
end

Given /^customer "(.*) (.*)" has the following (subscriber )?reservations:/ do |first,last,sub,table|
  customer = find_or_create_customer(first,last)
  table.hashes.each do |res|
    vtype = find_or_create_or_default res[:vouchertype], (sub ? :vouchertype_included_in_bundle : :revenue_vouchertype)
    showdate = setup_show_and_showdate(res[:show], res[:showdate])
    vv = create(:valid_voucher, :vouchertype => vtype, :showdate => showdate)
    purchasemethod = purchasemethod_from_string res[:purchasemethod]
    order = build(:order, :customer => customer, :purchaser => customer, :purchasemethod => purchasemethod)
    order.add_tickets(vv, res[:qty].to_i)
    order.finalize!
  end
end

Given /^an order for customer "(.*) (.*)" containing the following tickets:/ do |first,last,table|
  customer = find_or_create_customer(first,last)
  # make it legal for customer to buy the things
  @order = build(:order,
    :purchasemethod => Purchasemethod.find_by_shortdesc('box_cash'),
    :customer => customer,
    :purchaser => customer)
  @order.vouchers = []
  table.hashes.each do |voucher|
    vtype = Vouchertype.find_by_name(voucher[:name]) || create(:revenue_vouchertype, :name => voucher[:name])
    vv = create(:valid_voucher, :vouchertype => vtype, :showdate => nil)
    @order.add_tickets(vv, voucher[:quantity].to_i)
  end
  @order.finalize!
end

Then /^customer "(.*) (.*)" should have an order (with comment "(.*)" )?containing the following tickets:$/ do |first,last,_,comments,table|
  @customer = find_customer!(first,last)
  order = @customer.orders.first
  order.comments.should == comments
  table.hashes.each do |item|
    matching_items = order.vouchers.select { |v| v.vouchertype.name == item['type'] }
    unless item['showdate'].blank?
      matching_items.reject! { |v| v.showdate != Showdate.find_by_thedate(Time.parse(item['showdate'])) }
    end
    matching_items.length.should == item['qty'].to_i
  end
end

When /^I place my order with a valid credit card$/ do
  # relies on stubbing Store.purchase_with_credit_card method
  steps %Q{When I press "Charge Credit Card"}
  match = page.first('title').text.match(/confirmation of order (\d+)/i)
  match.should_not be_nil
  @order = Order.find($1)
end

When /^the order is placed successfully$/ do
  Store.stub!(:pay_with_credit_card).and_return(true)
  click_button 'Charge Credit Card' # but will be handled as Cash sale in 'test' environment
end

When /^I refund items? (.*) of that order$/ do |items|
  steps %Q{
    When I select items #{items} of that order
    And I refund that order
}
end

When /^I refund that order$/ do
  @order.should be_a_kind_of Order # setup by a previous step
  within "#order_#{@order.id}" do ;  click_button 'Refund Checked Items' ; end
end

When /^I (un)?select all the items in that order$/ do |un|
  page.all(:css, 'input.itemSelect').each do |e|
    if un then uncheck e['id'] else check e['id'] end
  end
end

When /^I (un)?select items? ([0-9, ]+) of that order$/ do |un, index|
  e = page.all(:css, "input.itemSelect")
  index.split(/, */).map(&:to_i).each do |i|
    if un then uncheck(e[i-1]['id']) else check(e[i-1]['id']) end
  end
end

When /^I check the transfer box for the (\d)(?:th|st|rd) "(.*)" voucher$/ do |ordinal,voucher_name|
  ordinal = ordinal.to_i
  raise "Can only get first element right now" unless ordinal==1
  td = "//table[@id='transfer_vouchers_table']//td[contains(text(),'#{voucher_name}')]"
  # navigate from the td to the checkbox at the beginning of its row
  checkbox = "#{td}/..//input[@type='checkbox']"
  find(:xpath, checkbox).set(true)
end
