Given /^an order for customer "(.*) (.*)" containing the following tickets:/ do |first,last,table|
  customer =
    Customer.find_by_first_name_and_last_name(first,last) ||
    create(:customer, :first_name => first, :last_name => last)
  # make it legal for customer to buy the things
  @order = build(:order,
    :purchasemethod => Purchasemethod.find_by_shortdesc('box_cash'),
    :customer => customer,
    :purchaser => customer)
  @order.vouchers = []
  table.hashes.each do |voucher|
    vtype = Vouchertype.find_by_name!(voucher[:name])
    vv = create(:valid_voucher, :vouchertype => vtype, :showdate => nil)
    @order.add_tickets(vv, voucher[:quantity].to_i)
  end
  @order.finalize!
end

Then /^customer "(.*) (.*)" should have an order (with comment "(.*)" )?containing the following tickets:$/ do |first,last,_,comments,table|
  @customer = Customer.find_by_first_name_and_last_name(first,last)
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
