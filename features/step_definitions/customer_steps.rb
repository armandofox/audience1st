module CustomerStepsHelper
  
  def find_customer(first,last, email=nil)
    email ? Customer.find_by(:first_name => first, :last_name => last, :email => email) : Customer.find_by(:first_name => first, :last_name => last)
  end

  def make_subscriber!(customer)
    vtype = create(:bundle, :subscription => true)
    voucher = Voucher.new_from_vouchertype(vtype)
    customer.vouchers << voucher
    customer.save!
    customer.should be_a_subscriber
  end

  def find_customer_by_fullname(name)
    c = Customer.find_by_first_name_and_last_name(*(name.split(/ +/))) or raise ActiveRecord::RecordNotFound
  end

  def find_or_create_customer(first,last)
    find_customer(first,last) || create(:customer, :first_name => first, :last_name => last)
  end

  def find_or_create_customer_with_email_and_password(first,last, email, password)
    c = find_customer(first, last, email) || create(:customer, :first_name => first, :last_name => last, :email => email, :password => password, :password_confirmation => password)
    c.bcrypt_password_storage(password)
  end

  def get_secret_question_index(question)
    indx = APP_CONFIG[:secret_questions].index(question)
    indx.should be_between(0, APP_CONFIG[:secret_questions].length-1)
    indx
  end
end
World(CustomerStepsHelper)

Then /^account creation should fail with "(.*)"$/ do |msg|
  steps %Q{
  Then I should see "#{msg}"
  And I should see "Create Your Account"
}
end

Given /^I (?:am acting on behalf of|switch to) customer "(.*) (.*)"$/ do |first,last|
  customer = find_or_create_customer first,last
  visit customer_path(customer)
  with_scope('div#on_behalf_of_customer') do
    page.should have_content("Customer: #{first} #{last}")
  end
end

Then /^I should be acting on behalf of customer "(.*)"$/ do |full_name|
  with_scope('#onBehalfOfName') do
    page.should have_content(full_name)
  end
end

Given /^customer "(.*) (.*)" should (not )?exist$/ do |first,last,no|
  @customer = find_customer first,last
  if no then @customer.should be_nil else @customer.should be_a_kind_of Customer end
end

Given /^customer "(.*) (.*)" exists( and was created by admin)?$/ do |first,last,admin|
  @customer = find_customer(first,last) ||
    create(:customer, :first_name => first, :last_name => last, :email => "#{first.downcase}@#{last.downcase}.com")
  @customer.update_attribute(:created_by_admin, true) if admin
end

Given /^the following customers exist: (.*)$/ do |list|
  list.split(/\s*,\s*/).each do |name|
    steps %Q{Given customer "#{name}" exists}
  end
end

# Searching for customers

When /^I search any field for "(.*)"$/ do |text|
  visit customers_path
  fill_in "customers_filter", :with => text
  with_scope '#search_on_any_field' do ; click_button 'Go' ; end
end

Given /^my birthday is set to "(.*)"/ do |date|
  @customer.update_attributes!(:birthday => Date.parse(date))
end

Then /^customer "(.*) (.*)" should have the following attributes:$/ do |first,last,attribs|
  customer = find_customer first,last
  dummy = Customer.new
  attribs.hashes.each do |attr|
    name,val = attr[:attribute], attr[:value]
    customer.send(name).should == Customer.columns_hash[name].cast_type.type_cast_from_database(val)
  end
end

Then /^customer "(.*) (.*)" should have a birthday of "(.*)"$/ do |first,last,date|
  find_customer(first,last).birthday.should ==
    Date.parse(date).change(:year => Customer::BIRTHDAY_YEAR)
end

Then /^customer "(.*) (.*)" should have the "(.*)" role$/ do |first,last,role|
  find_customer(first,last).role_name.should == role
end

When /^I select customers "(.*) (.*)" and "(.*) (.*)" for merging$/ do |f1,l1, f2,l2|
  c1 = find_or_create_customer f1,l1
  c2 = find_or_create_customer f2,l2
  visit customers_path
  check "merge[#{c1.id}]"
  check "merge[#{c2.id}]"
end

Given /^customer "(.*) (.*)" has email "(.*)" and password "(.*)"$/ do |first,last,email,pass|
  c = find_or_create_customer_with_email_and_password first,last,email,pass
  # c.update_attributes!(:email => email, :password => pass, :password_confirmation => pass)
end

Given /^customer "(.*) (.*)" (should have|has) secret question "(.*)" with answer "(.*)"$/ do |first,last,assert,question,answer|
  @customer = find_or_create_customer first,last
  if assert =~ /should/
    @customer.secret_question.should == get_secret_question_index(question)
    @customer.secret_answer.should == answer
  else
    @customer.update_attributes(
      :secret_question => get_secret_question_index(question),
      :secret_answer => answer)
  end
end

