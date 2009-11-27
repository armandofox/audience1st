require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Customer do
  describe "special customer that cannot fail validation or be destroyed:" do
    %w[walkup_customer generic_customer boxoffice_daemon].each do |c|
      it c.humanize do
        cust = Customer.send(c)
        cust.should be_valid
        lambda { cust.destroy }.should raise_error
      end
    end
  end
  describe "address validations" do
    context "with no mailing address" do
      before(:each) do
        @customer = Customer.create!(:first_name => "John", :last_name => "Doe")
      end
      it "should be valid" do
        @customer.should be_valid
      end
      it "should have a stand-in email address" do
        Option.stub!(:value).and_return('345')
        @customer.valid_email_address?.should be_false
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
  end
  
  describe "managing email subscriptions" do
    before(:each) do
      @email = "asdf@yahoo.com"
    end
    context "when opting out" do
      before(:each) do
        @customer = Customer.create!(:first_name => "J", :last_name => "D",
                                     :email => @email,
                                     :e_blacklist => false)
        @customer.e_blacklist = true # so it's marked dirty
      end
      it "should be unsubscribed using old email" do
        @customer.email_changed?.should_not be_true
        EmailList.should_receive(:unsubscribe).with(@customer,@email)
        @customer.save!
      end
      it "should be unsubscribed using old email even if email changed" do
        @customer.email = "newjohn@doe.com"
        @customer.email_changed?.should be_true
        EmailList.should_receive(:unsubscribe).with(@customer,@email)
        @customer.save!
      end
    end
    context "when opting in" do
      context "with new email address" do
        it "should be updated from old to new if old address was nonblank" do
          @customer = Customer.create!(:first_name => "J", :last_name => "D",
                                       :email => @email,
                                       :e_blacklist => true)
          @customer.e_blacklist = false
          @customer.email = "newjohn@doe.com"
          EmailList.should_receive(:update).with(@customer, @email)
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
                                     :email => @email,
                                     :e_blacklist => true)
        @customer.e_blacklist = false
        EmailList.should_receive(:subscribe).with(@customer)
        @customer.save!
      end
    end
  end

  describe "merging" do
    before(:each) do
      # stub out the merge handlers for associated attributes
      [Donation,Voucher,Txn].each do |klass|
        klass.stub!(:merge_handler).and_return(0)
      end
      # remove fractional seconds from time, else date comparisons fail!
      @now = Time.now.change(:usec => 0)
      @c1attrs = {:first_name => "f1", :last_name => "l1",
        :street => "s1", :city => "c1", :state => "s1",
        :zip => "88888", :day_phone => "p1", :email => "e1@a.com",
        :last_login => @now.yesterday, :login => "aaa",
        :updated_on => 2.days.ago,
        :hashed_password => 'olderpass' }
      @c1 = Customer.create!(@c1attrs)
      @c1.update_attribute(:role, 20)
      @c2attrs = {:first_name => "f2", :last_name => "l2",
        :street => "s2", :city => "c2", :state => "s2",
        :zip => "99999", :day_phone => "p2", :email => "e2@a.com",
        :last_login => @now, :login => "bbb",
        :updated_on => 1.day.ago,
        :hashed_password => 'newerpass'}
      @c2 = Customer.create!(@c2attrs)
      # role is a protected attribute
      @c2.update_attribute(:role, 10)
      # params with value of 1 should be copied , but hashed_password and some other
      # attribs are automatically kept from record with most recent activity,
      # and role always keeps the higher one
      @params = {:first_name => 0, :last_name => 1,
        :street => 0, :city => 0, :state => 0, :zip => 0,
        :day_phone => 1, :email => 1,
        :role => 1}
      @c1.should be_valid
      @c2.should be_valid
    end
    context "when result of merge is a valid customer" do
      before(:each) do
        @c1.merge_with(@c2,@params).should_not be_nil
      end
      it "should keep selected attributes of the merge" do
        # role & salt wouldn't normally appear in params, but was thrown in to test
        # the behavior when it is provided anyway - it shouldn't be assigned.
        @params.delete(:role)
        @params.each_pair do |attr,keep_new|
          if keep_new == 1
            @c1.send(attr).should == @c2.send(attr)
          else
            @c1.send("#{attr}_changed?").should be_false
          end
        end
      end
      it "should keep hashed_password and last_login based on most recent" do
        @c1.hashed_password.should == 'newerpass'
        @c1.last_login.should == @now
      end
      it "should keep the higher of the two roles" do
        @c1.role.should == 20
      end
      it "should delete the redundant customer" do
        Customer.find_by_id(@c2.id).should be_nil
        Customer.find_by_id(@c1.id).should be_a(Customer)
      end
    end
    context "when result of merge is NOT a valid customer" do
      before(:each) do
        # make c1's mailing address invalid, which is the one that will be kept
        # note that this would not normally occur if each of the two customers
        # was validated at save, but we check for it since some customer
        # records may predate some validation rules
        @c1.street = ''
        @c1.should_not be_valid
        @c1.merge_with(@c2,@params).should be_nil
      end
      it "should not delete the redundant customer" do
        Customer.find_by_id(@c2.id).should be_a(Customer)
      end
      it "should not modify either customer" do
        lambda { @c1 = Customer.find(@c1.id) }.should_not raise_error
        lambda { @c2 = Customer.find(@c2.id) }.should_not raise_error
        # compare the attributes using to_s,  because things like
        # dates are not == or eql even if refer to same date.
        @c1attrs.keys.reject { |s| s == :updated_on }.each do |attr|
          @c1.send(attr).should == @c1attrs[attr]
          @c2.send(attr).should == @c2attrs[attr]
        end
      end
      it "should add the errors to the first customer" do
        @c1.errors.full_messages.should_not be_empty
      end
    end
  end
  
end
