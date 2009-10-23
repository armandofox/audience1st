require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Store do

  describe "binding a ticket", :shared => true do
    it "should associate the ticket with the customer"
    it "should record the valid_voucher's account code in the voucher"
  end

  describe "walkup sale" do
    it_should_behave_like "binding a ticket"
    it "should associate the correct showdate with the voucher"
    it "should decrease the available seat count for the showdate"
  end

end
