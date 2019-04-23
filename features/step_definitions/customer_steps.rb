module CustomerStepsHelper
  
  def find_customer(first,last)
    Customer.find_by(:first_name => first, :last_name => last)
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

  def get_secret_question_index(question)
    questions = I18n.t('app_config.secret_questions')
    indx = questions.index(question)
    indx.should be_between(0, questions.length-1)
    indx
  end
end
World(CustomerStepsHelper)

Then /^account creation should fail with "(.*)"$/ do |msg|
  steps %Q{
  Then I should see "#{msg}"
  And I should see "Sign Up"
}
end

Given /^I (?:am acting on behalf of|switch to) customer "(.*) (.*)"$/ do |first,last|
  customer = find_or_create_customer first,last
  visit customer_path(customer)
  with_scope('#staffButtons') do
    page.should have_content(customer.full_name)
  end
end

Then /^I should be acting on behalf of customer "(.*)"$/ do |full_name|
  with_scope('#staffButtons') do
    page.should have_content(full_name)
  end
end

# Creating customers:
#  from a table
Given /^the following customers exist:$/ do |instances|
  instances.hashes.each do |hash|
    create(:customer, hash)
  end
end

# from names only
Given /^the following customers exist: (.*)$/ do |list|
  list.split(/\s*,\s*/).each do |name|
    steps %Q{Given customer "#{name}" exists}
  end
end

# specifying email and/or street address
Given /^customer "(.*) (.*)" exists( and was created by admin)?( with email "(.*)")?$/ do |first,last,admin,_,email|
  @customer = find_customer(first,last) ||
    create(:customer, :first_name => first, :last_name => last, :email => email||"#{first.downcase}@#{last.downcase}.com")
  @customer.update_attribute(:created_by_admin, true) if admin
  CustomersController.any_instance.stub(:generate_token).and_return("test_token")
end

Given /^customer "(.*) (.*)" whose address street is: "(.*)"$/ do |first,last,address|
  @customer = find_customer(first,last) ||
    create(:customer, :first_name => first,
           :last_name => last, :email => "#{first.downcase}@#{last.downcase}.com",
           :street => address)

end

Given /^customer "(.*) (.*)" has email "(.*)" and password "(.*)"$/ do |first,last,email,pass|
  c = find_or_create_customer first,last
  c.update_attributes!(:email => email, :password => pass, :password_confirmation => pass)
end

Given /^customer "(.*) (.*)" has no email address$/ do |first,last|
  @customer = find_or_create_customer first,last
  @customer.created_by_admin = true
  @customer.email = nil
  @customer.save!
end

Given /^customer "(.*) (.*)" has no contact info$/ do |first,last|
  @customer = find_customer first,last
  @customer.update_attributes!(:street => nil, :city => nil, :state => nil, :zip => nil)
end

Given /^customer "(.*) (.*)" should (not )?exist$/ do |first,last,no|
  @customer = find_customer first,last
  if no then @customer.should be_nil else @customer.should be_a_kind_of Customer end
end

Given /^customer "(.*) (.*)" has a birthday on "(.*)"/ do |first,last,date|
    @customer = find_customer first,last
    @customer.update_attributes!(:birthday => Date.parse(date))
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

