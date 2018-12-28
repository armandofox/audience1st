When /^I fill in an? (in)?valid credit card for "(.*)"$/ do |invalid,name|
  within "#credit_card" do
    fill_in "Name", :with => name
    select Time.current.month, :from => 'credit_card_month'
    select 1+Time.current.year, :from => 'credit_card_year'
    fill_in "CVV code", :with => '333'
    fill_in "Number", :with => '4242424242424242'
  end
end
