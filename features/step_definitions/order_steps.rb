When /^I place my order with a valid credit card$/ do
  # relies on stubbing Store.purchase_with_credit_card method
  steps %Q{Given I am on the checkout page
           And I press "Charge Credit Card"}
end
