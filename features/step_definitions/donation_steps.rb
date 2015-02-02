def find_or_create_account_code(full_name)
  if full_name =~ /^(\d+)\s+(.*)$/
    code,name = $1,$2
  else
    code,name = '0000', full_name
  end
  AccountCode.find_by_code(code) || AccountCode.find_by_name(name) || AccountCode.create!(:name => name, :code => code)
end

Given /^the following donations:$/ do |donations|
  donations.hashes.each do |donation|
    steps %Q{Given a donation of #{donation[:amount]} on #{donation[:date]} from "#{donation[:donor]}" to the "#{donation[:fund]}"}
  end
end

Given /^a donation of \$?([0-9.]+) on (\S+) from "(.*)" to the "(.*)"(by check|by cash|by credit card)?$/ do |amount,date,customer,fund,how|
  steps %Q{Given customer \"#{customer}\" exists}
  account_code = fund.blank? ? AccountCode.default_account_code : find_or_create_account_code(fund)
  order = Order.new_from_donation(amount, account_code, @customer)
  order.processed_by = @customer
  order.purchasemethod = Purchasemethod.get_type_by_name(
    case how
    when /cash/ then 'box_cash'
    when /credit/ then 'box_cc'
    else 'box_chk'
    end)
  begin
    order.finalize!(date)
  rescue Exception => e
    raise "Finalize error: #{order.errors.full_messages}"
  end
end

Then /^I should (not )?see the following donations:$/ do |no,donations|
  donations.hashes.each do |donation|
    regexp = "#{donation[:donor]}|||#{donation[:amount].to_i}||||"
    steps %Q{Then I should #{no}see a row "#{regexp}" within "table[@id='donations']"}
  end
end

Then /^customer "(.*)" should have a donation of \$([0-9.]+) to "(.*)"$/ do |customer_name,amount,fund|
  steps %Q{
    Given I am logged in as staff
    And I visit the donations page
    And I press "Search"
    Then I should see a row "#{customer_name}|||#{amount}||||" within "table[@id='donations']"
  }
end
