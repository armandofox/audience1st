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
  it "should create a new company if company does not exist" do
    @cust.company = "Google"
    migrate_company(@cust)
    expect(Company.where(:name => "Google").length).to eq(1)
    @comp = Company.where(:name => "Google")
  end
  it "should add customer to new company and new company to customer" do
    @cust.company = "Google"
    migrate_company(@cust)
    expect(Company.where(:name => "Google").length).to eq(1)
    @company = Company.where(:name => "Google").all.first
    expect(@cust.groups.all.first).to eq(@company)
    #the code below is to fix a weird interaction. @company.customers.all
    #can be length 1, and refer to some customer. but calling
    #@company.customers.all.first will return a new instance of
    #the same customer, even though only 1 exists in the database,
    #causing expect statements to fail. This is a workaround
    expect(@company.customers.length).to eq(1)
    expect(Customer.where(:first_name => "dbtest").length).to eq(1)
    expect(@company.customers.all.first.first_name).to eq(@cust.first_name)
  end
  it "should add customer to existing company if company exists" do
    @company = Company.create(:name => "Samsung")
    @cust.company = "Samsung"
    migrate_company(@cust)
    expect(Company.where(:name => "Samsung").length).to eq(1)
    expect(@cust.groups.length).to eq(1)
    expect(@cust.groups.all.first).to eq(@company)
    expect(@company.customers.length).to eq(1)
    expect(Customer.where(:first_name => "dbtest").length).to eq(1)
    expect(@company.customers.all.first.first_name).to eq(@cust.first_name)
  end
end
