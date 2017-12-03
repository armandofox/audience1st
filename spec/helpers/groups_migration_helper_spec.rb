require 'rails_helper'
describe GroupsMigrationHelper do
  before :each do
    @cust = Customer.new()
    @cust.first_name = "dbtest"
    @cust.save(validate: false)
  end
  it "should not do anything if customer has no company" do
    migrate_company(@cust)
    expect(Group.where(:name => nil).length).to eq(0)
    expect(@cust.groups.length).to eq(0)
  end
  it "should create a new company" do
    @cust.company = "Google"
    migrate_company(@cust)
    expect(Company.where(:name => "Google").length).to eq(1)
    @comp = Company.where(:name => "Google")
  end
  it "should add customer to company and company to customer" do
    @cust.company = "Google"
    migrate_company(@cust)
    expect(Company.where(:name => "Google").length).to eq(1)
    @company = Company.where(:name => "Google").all.first
    expect(@cust.groups.all.first).to eq(@company)
    expect(@company.customers.length).to eq(1)
    expect(Customer.where(:first_name => "dbtest").length).to eq(1)
    expect(@company.customers.all.first.first_name).to eq(@cust.first_name)
    @cust.destroy
  end
end
