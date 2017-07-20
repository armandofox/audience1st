When /^I fill in an? (in)?valid credit card for "(.*) (.*)"$/ do |valid,first,last|
  within "#credit_card" do
    fill_in "First Name", :with => first
    fill_in "Last Name", :with => last
    fill_in "credit_card_month", :with => Time.now.month
    fill_in "credit_card_year", :with => '2050'
    fill_in "Security (CVV) code", :with => '333'
    fill_in "Number (no spaces)", :with =>
      valid =~ /in/ ? '4000000000000002' : '4242424242424242'
    # invalid card number is Stripe's test number for "card declined"
  end
end
