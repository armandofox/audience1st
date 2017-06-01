Given /the following customers and labels exist/ do |customers_labels|
  customers_labels.hashes.each do |entry|
    customer = Customer.find_by_first_name_and_last_name(entry[:first_name], entry[:last_name]) ||
      create(:customer, :first_name => entry[:first_name], :last_name => entry[:last_name])
    entry[:labels].split(/\s*,\s*/).each do |label|
      customer.labels << (Label.find_by_name(label) || create(:label, :name => label))
    end
  end
end

Given /the label "(.*)" exists/ do |name|
  Label.find_or_create_by_name(name)
end

Given /the label "(.*)" does not exist/ do |name|
  l = Label.find_by_name(name)
  l.destroy if l
end

Given /customer "(.*)" has label "(.*)"/i do |cust,label|
  c = find_customer_by_fullname(cust)
  c.labels  << Label.find_or_create_by_name(label)
end

Then /customer "(.*)" should have label "(.*)"/i do |cust,label|
  c = find_customer_by_fullname(cust)
  c.labels.map { |l| l.name }.should include(label)
end

Then /customer "(.*)" should not have label "(.*)"/i do |cust,label|
  c = find_customer_by_fullname(cust)
  c.labels.map { |l| l.name }.should_not include(label)
end
