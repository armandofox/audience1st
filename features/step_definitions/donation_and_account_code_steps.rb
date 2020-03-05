module ScenarioHelpers
  module Donations
    def find_or_create_account_code(full_name)
      if full_name =~ /^(\d+)\s+(.*)$/
        code,name = $1,$2
      else
        code,name = '0000', full_name
      end
      AccountCode.find_by_code(code) || AccountCode.find_by_name(name) || AccountCode.create!(:name => name, :code => code)
    end
  end
end
World(ScenarioHelpers::Donations)

# creating/recording donations and account codes

Given /^the following account codes exist:$/ do |tbl|
  tbl.hashes.each do |acc_code|
    ac = create(:account_code, :code => acc_code["code"], :name => acc_code["name"],
      :description => acc_code["description"], :donation_prompt => acc_code["donation_prompt"])
    used_for = acc_code["used_for"]
    case used_for
    when /donations/i
      Option.first.update_attributes!(:default_donation_account_code => ac.id)
    else
      used_for.to_s.split(/\s*,\s*/).each do |vtype_name|
        Vouchertype.find_by!(:name => vtype_name).update_attributes!(:account_code => ac)
      end
    end
  end
end

When /I change the "(.*)" for account code (\d+) to "(.*)"/ do |attrib, account_code, new_value|
  ac = AccountCode.find_by!(:code => account_code)
  visit edit_account_code_path(ac)
  fill_in attrib, :with => new_value
  click_button 'Update Account code'
end

When /^I record a (check|cash) donation of \$([\d.]+) to "(.*)" on (.*)(?: with comment "(.*)")?$/ do |type, amount, fund, date, comment|
  fill_in "Amount", :with => amount
  choose type.capitalize
  select (find_or_create_account_code(fund).name_with_code.gsub(/\s+/, ' ')), :from => 'Fund'
  select_date_from_dropdowns date, :from => 'Date Posted'
  fill_in "Comments/Check no.", :with => comment.to_s
end

Given /^the following donations:$/ do |donations|
  donations.hashes.each do |donation|
    steps %Q{Given a donation of #{donation[:amount]} on #{donation[:date]} from "#{donation[:donor]}" to the "#{donation[:fund]}" with comment "#{donation[:comment]}"}
  end
end

Given /^a donation of \$([0-9.]+) on (\S+) from "(.*)" to the "(.*?)"(?: with comment "(.*)")?$/ do |amount,date,customer,fund,comment|
  steps %Q{Given customer \"#{customer}\" exists}
  account_code = fund.blank? ? AccountCode.default_account_code : find_or_create_account_code(fund)
  order = Order.new_from_donation(amount, account_code, @customer)
  order.processed_by = @customer
  order.comments = comment if comment
  order.purchasemethod = Purchasemethod.get_type_by_name('box_chk')
  begin
    order.finalize!(date)
  rescue Exception => e
    raise "Finalize error: #{order.errors.full_messages}"
  end
end

# editing/modifying donations

When /I fill in "(.*)" as the comment on (.*)'s donation/ do |comment,name| # '
  table_row = page.find(:xpath, "//a[text()='#{name}']/../..")
  comment_field = table_row.find(:css, '.donation-comment')
  comment_field.set(comment)
end

# checking for presence/attributes of donations

Then /^customer "(\S+) (.*)" should have an order dated "(.*)" containing a (.*) donation of \$(.*) to "(.*)"$/ do |first,last,date,type,amount,fund|
  date = Time.zone.parse(date)
  account_code = AccountCode.find_by_name!(fund)
  amount = amount.to_f
  orders = find_customer(first,last).orders.where(:sold_on => (date.at_beginning_of_day..date.at_end_of_day))
  matching_order = orders.any? do |order|
    order.purchase_medium == type.to_sym &&
      order.donations.length > 0 &&
      (d = order.donations.first).amount == amount &&
      d.account_code == account_code
  end
  expect(matching_order).to be_truthy
end

Then /^I should (not )?see the following donations:$/ do |no,donations|
  donations.hashes.each do |donation|
    regexp = "#{donation[:donor]}|||#{donation[:amount].to_i}||||"
    steps %Q{Then I should #{no}see a row "#{regexp}" within "table[@id='donations']"}
  end
end
