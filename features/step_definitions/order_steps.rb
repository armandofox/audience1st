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
  steps %Q{Given I am on the checkout page
           And I press "Charge Credit Card"}
end

When /^the order is placed successfully$/ do
  Store.stub!(:pay_with_credit_card).and_return(true)
  click_button 'Charge Credit Card' # but will be handled as Cash sale in 'test' environment
end

