Given /the label "(.*)" exists/ do |name|
  find_or_create_label(name)
end

Given /the label "(.*)" does not exist/ do |name|
  l = Label.find_by_name(name)
  l.destroy if l
end

Given /customer "(.*)" has label "(.*)"/i do |cust,label|
  c = find_customer_by_fullname(cust)
  c.labels  << find_or_create_label(label)
end

Then /customer "(.*)" should have label "(.*)"/i do |cust,label|
  c = find_customer_by_fullname(cust)
  c.labels.map { |l| l.name }.should include(label)
end

Then /customer "(.*)" should not have label "(.*)"/i do |cust,label|
  c = find_customer_by_fullname(cust)
  c.labels.map { |l| l.name }.should_not include(label)
end
