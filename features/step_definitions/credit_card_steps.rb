When /^I fill in an? (in)?valid credit card for "(.*)"$/ do |valid,name|
  within "#credit_card" do
    fill_in "Name", :with => name
    fill_in "credit_card_month", :with => Time.current.month
    fill_in "credit_card_year", :with => 1 + Time.current.year
    fill_in "CVV code", :with => '333'
    fill_in "Number", :with => '4242424242424242'
  end
end
