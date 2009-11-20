require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Store do

  describe "finalizing a ticket", :shared => true do
    it "should decrease the available seat count for the showdate"
    it "should record the valid_voucher's account code in the voucher"
  end

  describe "walkup sale" do
    it_should_behave_like "finalizing a ticket"
    it "should associate the correct showdate with the voucher"
    it "should associate the ticket with Walkup Customer"
  end

  describe "online purchase" do
    describe "generally", :shared => true do
      it_should_behave_like "finalizing a ticket"
    end
    describe "for self" do
      it_should_behave_like "generally"
      it "should associate the ticket with the buyer"
    end
    describe "as gift" do
      it_should_behave_like "generally"
      it "should associate the ticket with the gift recipient"
      it "should identify the buyer as the gift purchaser"
    end
  end
end
