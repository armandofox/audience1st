# -*- coding: utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Customer do
  fixtures :customers
  describe "when created by admin" do
    def new_by_admin(args={})
      (c = Customer.new(args)).created_by_admin = true
      c
    end
    before(:each) do
      @customer = new_by_admin(:first_name => "John", :last_name => "Do",
        :email => "johndoe111@yahoo.com",
        :password => "pass", :password_confirmation => "pass")
    end
    it "should not require email address" do
      @customer.email = nil
      @customer.should be_valid
      lambda { @customer.save! }.should_not raise_error
    end
    it "should not require password" do
      @customer.password = @customer.password_confirmation = nil
      @customer.should be_valid
      lambda { @customer.save! }.should_not raise_error
    end
    it "should be valid if only first initial and last name provided" do
      @customer = new_by_admin(:first_name => 'A', :last_name => 'Fox')
      @customer.should be_valid
    end
  end
  describe "when created/imported by daemon using force_valid" do
    it "should be forced to valid" do
      @customer = Customer.new(:first_name => "<bad", :last_name => '', :email => 'Bad Email')
      @customer.force_valid = true
      lambda { @customer.save! }.should_not raise_error
      @customer.first_name.should_not be_blank
      @customer.last_name.should_not be_blank
      @customer.email.should be_blank
    end
  end
  describe "when self-created" do
    before(:each) do
      @customer = Customer.new(:first_name => "John", :last_name => "Do",
        :email => "johndoe111@yahoo.com",
        :password => "pass", :password_confirmation => "pass")
    end
    it "should allow &" do
      @customer.first_name = "John & Mary"
      @customer.should be_valid
    end
    it "should allow /" do
      @customer.last_name = "Smith/Jones"
      @customer.should be_valid
    end
    it "should allow lists" do
      @customer.first_name = "John, Mary, & Joan"
      @customer.should be_valid
    end
    it "should disallow potential HTML/Javascript tags" do
      @customer.last_name = "<Doe>"
      @customer.should_not be_valid
    end
    it "should require valid email address" do
      @customer.email = nil
      @customer.should_not be_valid
    end
    it "should reject invalid email address" do
      @customer.email = "NotValidAddress"
      @customer.should_not be_valid
      @customer.errors.on(:email).should_not be_empty
    end
    it "should require password" do
      @customer.password = @customer.password_confirmation = ''
      @customer.should_not be_valid
      @customer.errors_on(:password).join(",").should match(/too short/i)
    end
    it "should require nonblank password confirmation" do
      @customer.password_confirmation = ''
      @customer.should_not be_valid
      @customer.errors.on(:password).should match(/doesn't match confirmation/i)
    end
    it "should require matching password confirmation" do
      @customer.password_confirmation = "DoesNotMatch"
      @customer.should_not be_valid
      @customer.errors.on(:password).should match(/doesn't match confirmation/i)
    end
  end
  describe "special customer that cannot fail validation or be destroyed:" do
    %w[walkup_customer generic_customer boxoffice_daemon].each do |c|
      it c.humanize do
        cust = Customer.send(c)
        lambda { cust.destroy }.should raise_error
      end
    end
  end
  describe "address validations" do
    context "with no mailing address" do
      before(:each) do
        @customer = Customer.create!(:first_name => "John", :last_name => "Doe",
          :password => 'xxxx', :password_confirmation => 'xxxx',
          :email => 'john@doe2.com')
      end
      it "should be valid" do
        @customer.should be_valid
      end
      it "should have a stand-in email address" do
        @customer.stub!(:email).and_return nil
        Option.stub!(:value).and_return('345')
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
        @customer = BasicModels.create_generic_customer
      end
      it "should be valid" do
        @customer.should be_valid
      end
      it "should be invalid if some address fields not filled in" do
        @customer.city = ''
        @customer.should_not be_valid
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
      @customer = BasicModels.create_generic_customer
      @email = @customer.email
    end
    context "when changing name only" do
      it "should be updated with new name even if email doesn't change" do
        @customer.update_attributes!(:e_blacklist => false)
        @customer.first_name = "Newfirstname"
        EmailList.should_receive(:update).with(@customer, @email)
        @customer.save!
      end
      it "should not be updated if previously opted out" do
        @customer.update_attributes!(:e_blacklist => true)
        @customer.first_name = "Newfirstname"
        EmailList.should_not_receive(:update)
        @customer.save!
      end
      it "should not be updated if now opting out" do
        @customer.update_attributes!(:e_blacklist => false)
        @customer.first_name = "Newfirstname"
        @customer.e_blacklist = true
        EmailList.should_not_receive(:update)
        @customer.save!
      end
    end
    context "when opting out" do
      before(:each) do
        @customer = BasicModels.create_generic_customer
        @customer.update_attributes!(:e_blacklist => false)
        @email = @customer.email
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
      before(:each) do
        @customer = BasicModels.create_generic_customer
        @customer.update_attributes!(:e_blacklist => true)
        @email = @customer.email
      end
      it "with new email address should be updated to new if old address was nonblank" do
        @customer.e_blacklist = false
        @customer.email = "newjohn@doe.com"
        EmailList.should_receive(:update).with(@customer, @email)
        @customer.save!
      end
      it "should be subscribed with new email if old email was blank" do
        @customer.e_blacklist = false
        EmailList.should_receive(:subscribe).with(@customer)
        @customer.save!
      end
      it "with same email address should be subscribed with new email" do
        @customer.e_blacklist = false
        EmailList.should_receive(:subscribe).with(@customer)
        @customer.save!
      end
    end
  end
  describe "find unique" do
    def names_match(a,b)
      our_first,our_last = a.split(/ +/)
      given_first,given_last = b.split(/ +/)
      Customer.new(:first_name => our_first, :last_name => our_last).name_matches(given_first,given_last)
    end
    context "when email matches" do
      before(:each) do
        @attrs = {:first_name => 'Bob', :last_name => 'Jones',
          :email => 'bobjones@mail.com',
          :street => '1234 Fake St',
          :city => 'New York', :state => 'NY', :zip => '99999'
        }
        @old = BasicModels.create_generic_customer(@attrs)
        @cust = Customer.new(@attrs)
      end
      context "and last name matches" do
        it "should match without an address" do
          [:street,:city,:state,:zip].each { |e| @attrs.delete(e) }
          Customer.find_unique(@cust).should == @old
        end
        it "should match even if addresses differ" do
          @cust.street = '999 New St'
          Customer.find_unique(@cust).should == @old
        end
        it "should match even if first names differ" do
          @cust.first_name = 'Bill'
          Customer.find_unique(@cust).should == @old
        end
      end
      context "but last name differs" do
        it "should not match if first name also differs" do
          @cust.first_name = 'Bill' ; @cust.last_name = 'Smith'
          Customer.find_unique(@cust).should be_nil
        end
      end
    end
    context "when email cannot break ties", :shared => true do
      before(:each) do
        @attrs = {:first_name => 'Bob', :last_name => 'Smith',
          :street => '99 Fake Blvd', :city => 'New York',
          :state => 'NY', :zip => '99999',
        :created_by_admin => true}
        @old = BasicModels.create_generic_customer(
          @attrs.merge(:email => @old_email))
        @new = Customer.new(@attrs.merge(:email => @new_email))
      end
      it "should match if first, last and address all match" do
        Customer.find_unique(@new).should == @old
      end
      [:first_name, :last_name, :street].each do |attr|
        it "should not match if #{attr} is blank in database" do
          @old.send("#{attr}=", nil)
          if @old.valid?
            @old.save
            Customer.find_unique(@new).should be_nil
          else
            true
          end
        end
        it "should not match if #{attr} is different in database" do
          @old.update_attribute(attr, @old.send(attr) << "XXX")
          Customer.find_unique(@new).should be_nil
        end
      end
    end
    context "when email isn't in our database" do
      before(:each) do
        @old_email = "nonexistent@here.com"
        @new_email = 'different@here.com'
      end
      it_should_behave_like "when email cannot break ties"
    end
    context "when email has >1 match" do
      before(:each) do
        @old_email = 'old1@here.com'
        @old2 = BasicModels.create_generic_customer(
          :email => 'old1@here.com', :created_by_admin => true)
      end
      it_should_behave_like "when email cannot break ties"
    end
    context "when email is not given" do
      before(:each) do
        @old_email = 'old_email@here.com'
        @new_email = nil
      end
      it_should_behave_like "when email cannot break ties"
    end
    context "when we have only a name" do
      # one could argue that if all we have is a name, even if it matches
      # uniquely, it could  be a very common name.  But if all we have
      # is a name and no other info on either side, it doesn't matter much.
      it "should match if first & last name match uniquely and exactly" do
        @old = BasicModels.create_generic_customer(:first_name => 'Joe', :last_name => 'Jones')
        Customer.find_unique(Customer.new(:first_name => 'Joe', :last_name => 'Jones')).should  == @old
      end
      it "should not match if first & last match exactly but not uniquely" do
        2.times { BasicModels.create_generic_customer(:first_name => 'Joe', :last_name => 'Jones') }
        Customer.find_unique(Customer.new(:first_name => 'Joe', :last_name => 'Jones')).should be_nil
      end
    end
  end
  describe "value selection for merging" do
    before(:each) do
      @old = BasicModels.create_generic_customer
      @new = BasicModels.create_generic_customer
      @old.stub!(:fresher_than?).and_return(nil)
      @new.stub!(:fresher_than?).and_return(true)
      Customer.stub!(:save_and_update_foreign_keys).and_return(true)
    end
    def try_merge(param,value_to_keep,value_to_discard)
      @old.update_attribute(param, value_to_keep)
      @new.update_attribute(param, value_to_discard)
      @old.merge_automatically!(@new).should_not be_nil
      @old.send(param).should == value_to_keep
    end
    describe "for single-value attributes (other than password)" do
      it "should set e_blacklist to most conservative" do
        try_merge(:e_blacklist, true, false)
      end
      it "should keep more recent last_login" do
        try_merge(:last_login, 1.day.ago, 2.days.ago)
      end
      it "should clear created-by-admin flag if at least 1 record was customer-created" do
        try_merge(:created_by_admin, false, true)
      end
      it "should keep older creation date" do
        try_merge(:created_at, 1.month.ago, 1.day.ago)
      end
      it "should concatenate comments" do
        @old.update_attribute(:comments, "foo")
        @new.update_attribute(:comments, "bar")
        @old.merge_automatically!(@new)
        @old.comments.should == "foo; bar"
      end
      it "should keep a single nonblank comment" do
        @new.update_attribute(:comments, "foo")
        @old.merge_automatically!(@new)
        @old.comments.should == "foo"
      end        
      it "should merge tags removing duplicates" do
        @old.update_attribute(:tags, "foo  Bar")
        @new.update_attribute(:tags, "bar baz")
        @old.merge_automatically!(@new)
        @old.tags.should == "foo bar baz"
      end
      it "should keep the higher of the two roles" do
        @old.update_attribute(:role, 20)
        @new.update_attribute(:role, 10)
        @old.merge_automatically!(@new).should_not be_nil
        @old.role.should == 20
      end
      describe "for Facebook data" do
        it "should keep facebook ID if first customer had one" do
          @old.fb_user_id = 56789
          @old.merge_automatically!(@new).should_not be_nil
          @old.fb_user_id.should == 56789
        end
        it "should keep facebook ID if second customer had one" do
          @new.fb_user_id = 98765
          @old.merge_automatically!(@new).should_not be_nil
          @old.fb_user_id.should == 98765
        end
        it "should keep fresher user's facebook ID if both have one" do
          @old.fb_user_id = 56789
          @new.fb_user_id = 98765
          @old.merge_automatically!(@new)
          @old.fb_user_id.should == 98765
        end
        it "should keep older user's facebook ID if fresher's is blank" do
          @old.fb_user_id = 56789
          @new.fb_user_id = nil
          @old.merge_automatically!(@new)
          @old.fb_user_id.should == 56789
        end
      end
    end
    it "should keep selected attributes when merging manually" do
      # 0=keep value from @old, 1=keep value from @new
      @params = {:first_name => 0, :last_name => 1,
        :street => 0, :city => 0, :state => 0, :zip => 0,
        :day_phone => 1, :email => 1,
        :role => 1}
      @old.merge_with_params!(@new,@params).should_not be_nil
      @params.delete(:role)
      @params.each_pair do |attr,keep_new|
        if keep_new == 1
          @old.send(attr).should == @new.send(attr)
        else
          @old.send("#{attr}_changed?").should be_false
        end
      end
    end
  end
  describe "merging" do
    before(:each) do
      now = Time.now.change(:usec => 0)
      @old = BasicModels.create_generic_customer
      @new = BasicModels.create_generic_customer
      @old.stub!(:fresher_than?).and_return(nil)
      @new.stub!(:fresher_than?).and_return(true)
    end
    it "should work when a third record has a duplicate email" do
      @triplicate = BasicModels.create_generic_customer
      [@old, @new, @triplicate].each { |c| c.email = 'dupe@email.com' ; c.save(false) }
      # Since the 'triplicate' workaround relies on temporarily setting
      # the created-by-admin bit, make sure that bit gets properly reset.
      @old.update_attribute(:created_by_admin, false)
      @old.merge_automatically!(@new).should_not be_nil
      @old.reload
      @old.email.should == 'dupe@email.com'
      @old.created_by_admin.should be_false
    end
    describe "successfully" do
      it "should keep password based on most recent" do
        @old.update_attributes!(:password => 'olderpass', :password_confirmation => 'olderpass')
        @new.update_attributes!(:password => 'newerpass', :password_confirmation => 'newerpass')
        salt = @new.salt
        pass = @new.crypted_password
        @old.merge_automatically!(@new).should_not be_nil
        @old.reload
        @old.crypted_password.should == @old.encrypt('newerpass')
        @old.salt.should == salt
        @old.crypted_password.should == pass
      end
      it "should delete the redundant customer" do
        @old.merge_automatically!(@new).should_not be_nil
        Customer.find_by_id(@new.id).should be_nil
        Customer.find_by_id(@old.id).should be_a(Customer)
      end
    end
    describe "unsuccessfully" do
      before(:each) do
        @new.first_name = ''
        @new.should_not be_valid
      end
      it "should add the errors to the first customer" do
        @old.merge_automatically!(@new).should be_nil
        @old.errors.full_messages.should_not be_empty
      end
      it "should not delete the redundant customer" do
        @old.merge_automatically!(@new).should be_nil
        Customer.find_by_id(@new.id).should be_a(Customer)
      end
      it "should not modify the merge target" do
        lambda { @premerge = Customer.find(@old.id) }.should_not raise_error
        @old.merge_automatically!(@new).should be_nil
        Customer.find(@premerge.id).should == @premerge
        # Customer.columns.each do |c|
        #   col = c.name.to_sym
        #   @old.send(col).should == @old_clone.send(col) 
        # end
      end
      it "should not destroy the merge source" do
        @old.merge_automatically!(@new).should be_nil
        lambda { @new = Customer.find(@new.id) }.should_not raise_error
      end
    end
  end
  
  it 'resets password' do
    customers(:quentin).update_attributes!(:password => 'new password', :password_confirmation => 'new password').should_not be_false
    Customer.authenticate(customers(:quentin).email, 'new password').should == customers(:quentin)
  end

  it 'does not rehash password' do
    customers(:quentin).update_attributes(:email => 'quentin2@email.com').should_not be_false
    Customer.authenticate('quentin2@email.com', 'monkey').should == customers(:quentin)
  end

  #
  # Authentication
  #

  it 'authenticates user' do
    Customer.authenticate(customers(:quentin).email, 'monkey').should == customers(:quentin)
    Customer.authenticate(customers(:quentin).email, 'monkey').errors.should be_empty
  end

  context "invalid login" do
    it "should display a password-incorrect message for bad password" do
      Customer.authenticate(customers(:quentin).email, 'invalid_password').errors.on(:login_failed).
        should match(/password incorrect/i)
    end
    it "should display an unknown-username message for bad username" do
      Customer.authenticate('asdkfljhadf@email.com', 'pass').errors.on(:login_failed).
        should match(/can't find that email/i)
    end
  end

  if (!defined?(REST_AUTH_SITE_KEY) || REST_AUTH_SITE_KEY.blank?)
    # old-school passwords
    it "authenticates a user against a hard-coded old-style password" do
      Customer.authenticate(customers(:old_password_holder).email, 'test').should == customers(:old_password_holder)
    end
  else
    it "doesn't authenticate a user against a hard-coded old-style password" do
      Customer.authenticate(customers(:old_password_holder).email, 'test').should be_nil
    end

    # New installs should bump this up and set REST_AUTH_DIGEST_STRETCHES to give a 10ms encrypt time or so
    desired_encryption_expensiveness_ms = 0.1
    it "takes longer than #{desired_encryption_expensiveness_ms}ms to encrypt a password" do
      test_reps = 100
      start_time = Time.now; test_reps.times{ Customer.authenticate('quentin', 'monkey'+rand.to_s) }; end_time   = Time.now
      auth_time_ms = 1000 * (end_time - start_time)/test_reps
      auth_time_ms.should > desired_encryption_expensiveness_ms
    end
  end

  #
  # Authentication
  #

  it 'sets remember token' do
    customers(:quentin).remember_me
    customers(:quentin).remember_token.should_not be_nil
    customers(:quentin).remember_token_expires_at.should_not be_nil
  end

  it 'unsets remember token' do
    customers(:quentin).remember_me
    customers(:quentin).remember_token.should_not be_nil
    customers(:quentin).forget_me
    customers(:quentin).remember_token.should be_nil
  end

  it 'remembers me for one week' do
    before = 1.week.from_now.utc
    customers(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    customers(:quentin).remember_token.should_not be_nil
    customers(:quentin).remember_token_expires_at.should_not be_nil
    customers(:quentin).remember_token_expires_at.between?(before, after).should be_true
  end

  it 'remembers me until one week' do
    time = 1.week.from_now.utc
    customers(:quentin).remember_me_until time
    customers(:quentin).remember_token.should_not be_nil
    customers(:quentin).remember_token_expires_at.should_not be_nil
    customers(:quentin).remember_token_expires_at.should == time
  end

  it 'remembers me default two weeks' do
    before = 2.weeks.from_now.utc
    customers(:quentin).remember_me
    after = 2.weeks.from_now.utc
    customers(:quentin).remember_token.should_not be_nil
    customers(:quentin).remember_token_expires_at.should_not be_nil
    customers(:quentin).remember_token_expires_at.between?(before, after).should be_true
  end

  protected
  def create_user(options = {})
    record = Customer.new({ :email => 'quire@example.com', :password => 'quire69', :password_confirmation => 'quire69' }.merge(options))
    record.save
    record
  end

end
