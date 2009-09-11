require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Customer do
  context "with no mailing address" do
    before(:each) do
      @customer = Customer.create!(:first_name => "John", :last_name => "Doe")
    end
    it "should be valid" do
      @customer.should be_valid
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
  context "with nonblank address" do
    before(:each) do
      @customer = Customer.create!(:first_name => "John", :last_name => "Doe",
                                   :street => "123 Fake St", :city => "Alameda",
                                   :state => "CA", :zip => "94501")
    end
    it "should be valid" do
      @customer.should be_valid
    end
    it "should be invalid if some address fields not filled in" do
      @customer.city = ''
      @customer.should_not be_valid
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

  describe "managing subcriptions" do
    context "when opting out" do
      before(:each) do
        @customer = Customer.create!(:first_name => "J", :last_name => "D",
                                     :email => "john@doe.com",
                                     :e_blacklist => false)
        @customer.e_blacklist = true # so it's marked dirty
      end
      it "should be unsubscribed using old email" do
        @customer.email_changed?.should_not be_true
        EmailList.should_receive(:unsubscribe).with(@customer,"john@doe.com")
        @customer.save!
      end
      it "should be unsubscribed using old email even if email changed" do
        @customer.email = "newjohn@doe.com"
        @customer.email_changed?.should be_true
        EmailList.should_receive(:unsubscribe).with(@customer,"john@doe.com")
        @customer.save!
      end
    end
    context "when opting in" do
      context "with new email address" do
        it "should be updated from old to new if old address was nonblank" do
          @customer = Customer.create!(:first_name => "J", :last_name => "D",
                                       :email => "john@doe.com",
                                       :e_blacklist => true)
          @customer.e_blacklist = false
          @customer.email = "newjohn@doe.com"
          EmailList.should_receive(:update).with(@customer, "john@doe.com")
          @customer.save!
        end
        it "should be subscribed with new email if old email was blank" do
          @customer = Customer.create!(:first_name => "J", :last_name => "D",
                                       :email => "",
                                       :e_blacklist => true)
          @customer.e_blacklist = false
          EmailList.should_receive(:subscribe).with(@customer)
          @customer.save!
        end
      end
      it "with same email address should be subscribed with new email" do
        @customer = Customer.create!(:first_name => "J", :last_name => "D",
                                     :email => "john@doe.com",
                                     :e_blacklist => true)
        @customer.e_blacklist = false
        EmailList.should_receive(:subscribe).with(@customer)
        @customer.save!
      end
    end
  end
end
