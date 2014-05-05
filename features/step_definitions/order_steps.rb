When /^I place my order with a valid credit card$/ do
  # relies on stubbing Store.purchase_with_credit_card method
  steps %Q{Given I am on the checkout page
           And I press "Charge Credit Card"}
end

When /^the order is placed successfully$/ do
  Store.stub!(:pay_with_credit_card).and_return(true)
  click_button 'Charge Credit Card' # but will be handled as Cash sale in 'test' environment
end

