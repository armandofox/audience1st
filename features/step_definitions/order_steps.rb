When /^I place my order with a valid credit card$/ do
  Given %Q{I am on the checkout page}
  # relies on stubbing Store.purchase_with_credit_card method
  And   %Q{I press "Charge Credit Card"}
end
