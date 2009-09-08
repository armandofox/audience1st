require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Customer do
  context "with only name and address filled in" do
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

  describe "email validations" do
    before(:each) do
      @customer = Customer.new
    end
    it "should have a valid email if email is provided" do
      @customer.email = "me@you.com"
      @customer.valid_email_address?.should be_true
    end
    it "should not be valid if email is provided but bogus" do
      @customer.email = "foo"
      @customer.valid_email_address?.should be_nil
    end
    it "may have a blank email" do
      @customer.email = ''
      @customer.valid_email?.should be_true
    end
  end

  describe "eligible as gift recipient" do
    before(:each) do
      @customer = Customer.new(:first_name => "John", :last_name => "Doe",
                               :day_phone => "555-1212",
                               :eve_phone => "666-2323")
      @customer.stub!(:invalid_mailing_address?).and_return(false)
      @customer.stub!(:valid_email_address?).and_return(true)
    end
    it "should be valid with valid attributes" do
      @customer.should be_valid_as_gift_recipient
    end
    it "should be valid even if only one phone number" do
      @customer.day_phone = nil
      @customer.should be_valid_as_gift_recipient
    end
    it "should have both first and last name" do
      @customer.first_name = nil
      @customer.should_not be_valid_as_gift_recipient
    end
    it "should have both first and last name, take 2" do
      @customer.last_name = nil
      @customer.should_not be_valid_as_gift_recipient
    end
    it "should have a valid mailing address" do
      @customer.stub!(:invalid_mailing_address?).and_return(true)
      @customer.should_not be_valid_as_gift_recipient
    end
    it "should have email if no day phone or eve phone" do
      @customer.eve_phone = nil
      @customer.day_phone =  nil
      @customer.should be_valid_as_gift_recipient
    end
    it "should have day phone if no email or eve phone" do
      @customer.stub!(:valid_email_address?).and_return(false)
      @customer.eve_phone = nil
      @customer.should be_valid_as_gift_recipient
    end
    it "should have eve phone if no email or day phone" do
      @customer.stub!(:valid_email_address?).and_return(false)
      @customer.day_phone = nil
      @customer.should be_valid_as_gift_recipient
    end
    it "should not be missing both phone numbers AND email" do
      @customer.day_phone = @customer.eve_phone = ''
      @customer.stub!(:valid_email_address?).and_return(false)
      @customer.should_not be_valid_as_gift_recipient
    end
  end

  describe "updating email address" do
    it "should return originally-loaded email if unchanged" do
      @customer = Customer.new(:first_name => "J", :last_name => "D",
                               :email => "old")
      @customer.email_when_loaded.should == "old"
    end
    it "should return originally-loaded email when changed to new" do
      @customer = Customer.new(:first_name => "J", :last_name => "D",
                               :email => "old")
      @customer.email = "new"
      @customer.email_when_loaded.should == "old"
      @customer.email.should == "new"
    end
  end

  describe "managing subcriptions" do
    before(:each) do
      @customer = Customer.new(:first_name => "J", :last_name => "D",
                               :email => "john@doe.com")
    end
    context "when e-blacklist becomes true" do
      it "should unsubscribe old (pre-update) email address"
      it "should be unsubscribed from Mailchimp if has valid email address" do
        @customer.e_blacklist = true
        EmailList.should_receive(:unsubscribe).with(@customer).and_return(true)
        @customer.save!
      end
      it "should take no action with Mailchimp if invalid email address" do
        @customer.e_blacklist = true
        @customer.email = ''
        EmailList.should_not_receive(:unsubscribe)
        @customer.save!
      end
    end
    context "when e-blacklist becomes false" do
      it "should be subscribed to Mailchimp if has valid email address"
      it "should take no action with Mailchimp if no valid email address"
    end
    context "when email address is updated" do
      it "should not update Mailchimp if e_blacklist is set"
      it "should update Mailchimp if new valid email address" 
      it "should unsubscribe old address from Mailchimp if new address invalid"
    end

  end
end
