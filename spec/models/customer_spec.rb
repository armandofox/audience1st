require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Customer do
  describe "with only name and address filled in" do
    before(:each) do
      @customer = Customer.create!(:first_name => "John", :last_name => "Doe")
    end
    it "should have a stand-in email address" do
      Option.stub!(:value).and_return('345')
      @customer.valid_email_address?.should == false
      @customer.possibly_synthetic_email.should ==
        "patron-345-#{@customer.id}@audience1st.com"
    end
    it "should have a stand-in phone number" do
      @customer.possibly_synthetic_phone.should == "555-555-5555"
    end
    it "should not be able to do credit card purchases" do
      @customer.should_not be_valid_as_purchaser
    end
    it "should not be a valid gift recipient" do
      @customer.should_not be_valid_as_gift_recipient
    end
  end

end
