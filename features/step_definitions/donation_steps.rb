Given /^a donation of \$?(.*) on (.*) from (.*)$/ do |amount,date,customer|
  Given "customer \"#{customer}\" exists"
  @customer.donations.create!(
    :amount => amount,
    :date => date,
    :account_code => AccountCode.default_account_code)
end
