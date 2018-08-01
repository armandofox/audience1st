When /^I fill in an? (in)?valid credit card for "(.*) (.*)"$/ do |valid,first,last|
  within "#credit_card" do
    fill_in "First Name", :with => first
    fill_in "Last Name", :with => last
    fill_in "credit_card_month", :with => Time.current.month
    fill_in "credit_card_year", :with => 1 + Time.current.year
    fill_in "Security (CVV) code", :with => '333'
    fill_in "Number (no spaces)", :with => '4242424242424242'
  end
end
