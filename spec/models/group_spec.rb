require 'rails_helper'

describe Group do
  before :each do
    @quentin = create :customer, first_name: 'quentin', last_name: 'q', email: 'quentin@example.com', password: 'monkey', password_confirmation: 'monkey', created_at: 5.days.ago, remember_token_expires_at: 1.day.from_now, remember_token: '77de68daecd823babbb58edb1c8e14d7106e83bb'
    @company = Company.create(:name => "google")
    @company.customers << @quentin
  end
  it "should not delete a customer if the group is deleted" do
    @company.destroy
    expect(Company.where(:name => "google").length).to eq(0)
    expect(Customer.where(:first_name => "quentin").first).to eq(@quentin)
  end
  it "should not delete a group if the customer is deleted" do
    @quentin.destroy
    expect(Company.where(:name => "google").length).to eq(1)
    expect(Customer.where(:first_name => "quentin").length).to eq(0)
  end
end
