When /^I fill in an? (in)?valid credit card for "(.*)"$/ do |invalid,name|
  within "#credit_card" do
    fill_in "Name", :with => name
    select Time.current.month.to_s, :from => 'credit_card_month'
    select (1+Time.current.year).to_s, :from => 'credit_card_year'
    fill_in "CVV code", :with => '333'
    fill_in "Number", :with => '4242424242424242'
  end
end

When /^I place my order with a valid credit card$/ do
  # relies on stubbing Store.purchase_with_credit_card method
  steps %Q{When I press "Charge Credit Card"}
  page.title.match(/confirmation of order (\d+)/i).should be_truthy
  @order = Order.find($1)
end

When /^the order is placed successfully$/ do
  allow(Store).to receive(:pay_with_credit_card).and_return(true)
  click_button 'Charge Credit Card' # but will be handled as Cash sale in 'test' environment
end
