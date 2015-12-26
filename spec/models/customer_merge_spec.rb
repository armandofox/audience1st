require 'spec_helper'

describe Customer, "merging" do
  describe "value selection" do
    before(:each) do
      @old = create(:customer)
      @new = create(:customer)
      @old.stub!(:fresher_than?).and_return(nil)
      @new.stub!(:fresher_than?).and_return(true)
      Customer.stub!(:save_and_update_foreign_keys).and_return(true)
    end
    def try_merge(param,value_to_keep,value_to_discard)
      @old.update_attribute(param, value_to_keep)
      @new.update_attribute(param, value_to_discard)
      @old.merge_automatically!(@new).should_not be_nil, @old.errors.full_messages.join(';')
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

  describe "deleting" do
    before :each do ;  @cust = create(:customer) ;  end
    def create_records(type,cust)
      Array.new(1+rand(4)) do |idx|
        e = type.new(:customer_id => cust.id)
        e.save(false)
        e.id
      end
    end
    def check_exists_and_linked_to_anonymous(t,objs)
      objs.each do |id|
        obj = t.find_by_id(id)
        obj.should_not be_nil
        obj.customer_id.should == Customer.anonymous_customer.id
      end
    end        
    context ",", :shared => true do
      it "should do nothing if customer is a special customer" do
        Customer.boxoffice_daemon.forget!.should be_nil
      end
      it "should not change any of special customer's attribute values" do
        @cust.update_attributes!(:blacklist => false, :e_blacklist => false)
        @cust.forget!
        Customer.anonymous_customer.blacklist.should be_true
        Customer.anonymous_customer.e_blacklist.should be_true
      end
    end
    context "using forget!" do
      it_should_behave_like ","
      it "should delete the record for the original customer" do
        old_id = @cust.id
        @cust.forget!
        Customer.find_by_id(old_id).should be_nil
      end
      [Donation, Voucher, Txn, Import].each do |t|
        it "should preserve old customer's #{t}s" do
          objs = create_records(t, @cust)
          t.count(:conditions => "customer_id = #{@cust.id}").should == objs.length
          @cust.forget!
          @cust.errors.should be_empty
          t.count(:conditions => "customer_id = #{@cust.id}").should be_zero
          check_exists_and_linked_to_anonymous(t,objs)
        end
      end
    end
  end

  describe "merging" do
    before(:each) do
      now = Time.now.change(:usec => 0)
      @old = create(:customer)
      @new = create(:customer)
      @old.stub!(:fresher_than?).and_return(nil)
      @new.stub!(:fresher_than?).and_return(true)
    end
    it "should work when a third record has a duplicate email" do
      pending "Need to handle this as a separate special case in merge"
      @triplicate = create(:customer)
      [@old, @new, @triplicate].each { |c| c.email = 'dupe@email.com' ; c.save(false) }
      # Since the 'triplicate' workaround relies on temporarily setting
      # the created-by-admin bit, make sure that bit gets properly reset.
      @old.update_attribute(:created_by_admin, false)
      @old.merge_automatically!(@new).should_not be_nil
      @old.reload
      @old.email.should == 'dupe@email.com'
      @old.created_by_admin.should be_false
    end
    describe "disallowed cases" do
      before :each do
        @c0 = create(:customer)
        @c1 = create(:customer)
      end
      it "should refuse if RHS is any Special customer" do
        @c1.stub!(:special_customer?).and_return true
        @c0.merge_automatically!(@c1).should be_nil
        @c0.errors.full_messages.should include_match_for(/special customers cannot be merged/i)
      end
      it "should allow if LHS is Anonymous customer" do
        c0 = Customer.anonymous_customer
        c0.merge_automatically!(@c1).should be_true
        lambda { Customer.find(@c1.id) }.should raise_error(ActiveRecord::RecordNotFound)
      end
      it "should refuse if LHS is any special customer other than Anonymous" do
        c0 = Customer.boxoffice_daemon
        c0.merge_automatically!(@c1).should be_nil
        c0.errors.full_messages.should include_match_for(/merges disallowed.*except anonymous/i)
      end
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
end
