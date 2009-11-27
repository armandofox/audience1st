require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe StoreController do

  describe "online purchase" do
    describe "generally", :shared => true do
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
