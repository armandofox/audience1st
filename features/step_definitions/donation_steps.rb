def find_or_create_account_code(full_name)
  if full_name =~ /^(\d+)\s+(.*)$/
    code,name = $1,$2
  else
    code,name = '0000', $2
  end
  AccountCode.find_by_code(code) || AccountCode.create_by_code(code, name)
end

Given /^the following donations:$/ do |donations|
  donations.hashes.each do |donation|
    Given %Q{a donation of #{donation[:amount]} on #{donation[:date]} from "#{donation[:donor]}" to the "#{donation[:fund]}"}
  end
end

Given /^a donation of \$?([0-9.]+) on (\S+) from "(.*)" to the "(.*)"$/ do |amount,date,customer,fund|
  Given "customer \"#{customer}\" exists"
  account_code = fund.blank? ? AccountCode.default_account_code : find_or_create_account_code(fund)
  @customer.donations.create!(
    :amount => amount,
    :sold_on => date,
    :account_code => account_code
    )
end

Then /^I should (not )?see the following donations:$/ do |no,donations|
  donations.hashes.each do |donation|
    regexp = "#{donation[:donor]}||#{donation[:amount].to_i}|||||"
    Then %Q[I should #{no}see a row "#{regexp}" within "table[@id='donations']"]
  end
end
