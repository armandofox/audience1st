module ScenarioHelpers
  module Customers
    
    def find_customer(first,last)
      Customer.find_by(:first_name => first, :last_name => last)
    end

    def make_subscriber!(customer)
      vtype = create(:bundle, :subscription => true)
      voucher = VoucherInstantiator.new(vtype).from_vouchertype.first
      customer.vouchers << voucher
      customer.save!
      expect(customer).to be_a_subscriber
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
      expect(indx).to be_between(0, questions.length-1)
      indx
    end
  end
end

World(ScenarioHelpers::Customers)

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
    expect(page).to have_content(customer.full_name)
  end
end

Then /^I should be acting on behalf of customer "(.*)"$/ do |full_name|
  with_scope('#staffButtons') do
    expect(page).to have_content(full_name)
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

Given /customer "(.*) (.*)" exists with no email/ do |first,last|
  @customer = create(:customer, :first_name => first, :last_name => last,
    :email => nil, :created_by_admin => true)
end

Given /^customer "(.*) (.*)" exists( with email "(.*)")?$/ do |first,last,email|
  @customer =
    find_customer(first,last) ||
    create(:customer, :first_name => first, :last_name => last,
    :email => (email||"#{first.downcase}@#{last.downcase}.com"))
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
  if no
    expect(@customer).to be_nil
  else
    expect(@customer).to be_a_kind_of Customer
  end
end

Then /customer "(.*) (.*)" should exist with email "(.*)"/ do |first,last,email|
  c = Customer.find_by_email(email)
  expect(c.first_name).to eq(first)
  expect(c.last_name).to eq(last)
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
  attribs.hashes.each do |attr|
    name,val = attr[:attribute], attr[:value]
    column_type = Customer.column_for_attribute(name).type
    object_after_cast = ActiveRecord::Type.lookup(column_type).cast(val)
    expect(customer.send(name)).to eq(object_after_cast)
  end
end

Then /^customer "(.*) (.*)" should have a birthday of "(.*)"$/ do |first,last,date|
  bday = find_customer(first,last).birthday
  expect(bday).to eq(Date.parse(date).change(:year => Customer::BIRTHDAY_YEAR))
end

Then /^customer "(.*) (.*)" should have the "(.*)" role$/ do |first,last,role|
  expect(find_customer(first,last).role_name).to eq(role)
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

