
Given /I enter the groups url/ do
  visit "/groups"
end


And(/^I select customers "([^"]*)" to add to groups$/) do |customers|
  list = customers.split(', ')
  customers = []
  list.each {|name|
    m = /^(.*) (.*)$/.match(name)
    # m[1] is the first name and m[2] is the last name
    customers.push(find_or_create_customer m[1], m[2])
  }
  visit customers_path
  customers.each {|c|
    check "merge[#{c.id}]"
  }
end

And(/^I select groups "([^"]*)"$/) do |groups|
  group_list = groups.split(', ')
  group_list.each {|name|
    c = Group.find_by(:name => name)
    check "group[#{c.id}]"
  }
end

Then(/^I will have a group "([^"]*)" with members "([^"]*)"$/) do |group, members|
  result = true
  member_list = members.split(', ')
  g = Group.find_by_name(group)
  g_mems = g.customers
  member_list.each { |mem_name|
    m = /^(.*) (.*)$/.match(mem_name)
    # m[1] is the first name and m[2] is the last name
    c = find_or_create_customer m[1], m[2]
    result = false unless g_mems.include?(c)
  }
  expect(result).to eq(true)
end
Then (/^the form should contain "(.*)" within "(.*)"/) do |text, field|
  page.should have_field(field, with: text)
end
Given /^a group named "(.*)" exists$/ do |name|
  @group = Group.create(:name => name)

end
And(/^I press the button "([^"]*)"$/) do |button|
  click_button(button)
end
Given /the groups database isn't seeded/ do
  Group.delete_all
end
Then(/^"(.*)" should not be in the database/) do |name|
  expect(Group.where(:name => name).length).to eq(0)
end
Given /I enter the groups page for "(.*)"/ do |name|
  visit group_path(Group.where(:name => name).all.first)
end
Given /I submit the form by pressing "Edit Group"/ do
  page.find('#Edit').click
end
