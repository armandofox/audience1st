require 'rails_helper'

describe Customer, "merging" do
  describe "value selection" do
    before(:each) do
      @old = create(:customer)
      @new = create(:customer)
      allow(@old).to receive(:fresher_than?).and_return(nil)
      allow(@new).to receive(:fresher_than?).and_return(true)
      allow(Customer).to receive(:save_and_update_foreign_keys!).and_return(true)
    end
    def try_merge(param,value_to_keep,value_to_discard)
      @old.update_attribute(param, value_to_keep)
      @new.update_attribute(param, value_to_discard)
      expect(@old.merge_automatically!(@new)).not_to be_nil, @old.errors.full_messages.join(';')
      expect(@old.send(param)).to eq(value_to_keep)
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
        expect(@old.comments).to eq("foo; bar")
      end
      it "should keep a single nonblank comment" do
        @new.update_attribute(:comments, "foo")
        @old.merge_automatically!(@new)
        expect(@old.comments).to eq("foo")
      end        
      it "should merge tags removing duplicates" do
        @old.update_attribute(:tags, "foo  Bar")
        @new.update_attribute(:tags, "bar baz")
        @old.merge_automatically!(@new)
        expect(@old.tags).to eq("foo bar baz")
      end
      it "should keep the higher of the two roles" do
        @old.update_attribute(:role, 20)
        @new.update_attribute(:role, 10)
        expect(@old.merge_automatically!(@new)).not_to be_nil
        expect(@old.role).to eq(20)
      end
    end
    it "should keep selected attributes when merging manually" do
      # 0=keep value from @old, 1=keep value from @new
      @params = {:first_name => 0, :last_name => 1,
        :street => 0, :city => 0, :state => 0, :zip => 0,
        :day_phone => 1, :email => 1,
        :role => 1}
      expect(@old.merge_with_params!(@new,@params)).not_to be_nil
      @params.delete(:role)
      @params.each_pair do |attr,keep_new|
        if keep_new == 1
          expect(@old.send(attr)).to eq(@new.send(attr))
        else
          expect(@old.send("#{attr}_changed?")).to be_falsey
        end
      end
    end
  end

  describe "provenance" do
    before :each do
      @old = create(:customer)
      @old.update_attribute(:created_at, 1.day.ago)
      @new = create(:customer)
    end
    context 'if older record created by import' do
      before :each do ; @old.update_attribute(:ticket_sales_import_id,999) ;  end
      specify 'keeps import ID (direction 1)' do
        @old.merge_automatically!(@new)
        expect(@old.ticket_sales_import_id).to eq(999)
      end
      specify 'keeps import ID (direction 2)' do
        @new.merge_automatically!(@old)
        expect(@new.ticket_sales_import_id).to eq(999)
      end
    end
    context 'if newer record created by import' do
      before :each do ; @new.update_attribute(:ticket_sales_import_id,999) ; end
      specify 'nils import ID (direction 1)' do
        @old.merge_automatically!(@new)
        expect(@old.ticket_sales_import_id).to be_nil
      end
      specify 'nils import ID (direction 2)' do
        @new.merge_automatically!(@old)
        expect(@new.ticket_sales_import_id).to be_nil
      end
    end
  end
  describe "deleting" do
    before :each do ;  @cust = create(:customer) ;  end
    def create_records(type,cust)
      Array.new(1+rand(4)) do |idx|
        e = cust.send(type.to_s.downcase.pluralize).new()
        e.save(:validate => false)
        e.id
      end
    end
    def check_exists_and_linked_to_anonymous(t,objs)
      objs.each do |id|
        obj = t.find_by_id(id)
        expect(obj).not_to be_nil
        expect(obj.customer_id).to eq(Customer.anonymous_customer.id)
      end
    end        
    shared_examples "," do
      it "should do nothing if customer is a special customer" do
        expect(Customer.boxoffice_daemon.forget!).to be_nil
      end
      it "should not change any of special customer's attribute values" do
        @cust.update_attributes!(:blacklist => false, :e_blacklist => false)
        @cust.forget!
        expect(Customer.anonymous_customer.blacklist).to be_truthy
        expect(Customer.anonymous_customer.e_blacklist).to be_truthy
      end
    end
    context "using forget!" do
      it_should_behave_like ","
      it "should delete the record for the original customer" do
        old_id = @cust.id
        @cust.forget!
        expect(Customer.find_by_id(old_id)).to be_nil
      end
      [Item, Txn, Order].each do |t|
        it "should preserve old customer's #{t}s" do
          objs = create_records(t, @cust)
          expect(t.where("customer_id = ?",@cust.id).count).to eq(objs.length)
          @cust.forget!
          expect(@cust.errors).to be_empty
          expect(t.where("customer_id = ?",@cust.id).count).to be_zero
          check_exists_and_linked_to_anonymous(t,objs)
        end
      end
    end
  end

  describe "merging" do
    before(:each) do
      now = Time.current.change(:usec => 0)
      @old = create(:customer)
      @new = create(:customer)
      allow(@old).to receive(:fresher_than?).and_return(nil)
      allow(@new).to receive(:fresher_than?).and_return(true)
    end
    it "should work when a third record has a duplicate email" do
      skip "Need to handle this as a separate special case in merge"
      @triplicate = create(:customer)
      [@old, @new, @triplicate].each { |c| c.email = 'dupe@email.com' ; c.save(:validate => false) }
      # Since the 'triplicate' workaround relies on temporarily setting
      # the created-by-admin bit, make sure that bit gets properly reset.
      @old.update_attribute(:created_by_admin, false)
      expect(@old.merge_automatically!(@new)).not_to be_nil
      @old.reload
      expect(@old.email).to eq('dupe@email.com')
      expect(@old.created_by_admin).to be_falsey
    end
    describe "disallowed cases" do
      before :each do
        @c0 = create(:customer)
        @c1 = create(:customer)
      end
      it "should refuse if RHS is any Special customer" do
        allow(@c1).to receive(:special_customer?).and_return true
        expect(@c0.merge_automatically!(@c1)).to be_nil
        expect(@c0.errors.full_messages).to include_match_for(/cannot be merged/i)
      end
      it "should allow if LHS is Anonymous customer" do
        c0 = Customer.anonymous_customer
        expect(c0.merge_automatically!(@c1)).to be_truthy
        expect { Customer.find(@c1.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
      it "should refuse if LHS is any special customer other than Anonymous" do
        c0 = Customer.boxoffice_daemon
        expect(c0.merge_automatically!(@c1)).to be_nil
        expect(c0.errors.full_messages).to include_match_for(/merges disallowed.*except anonymous/i)
      end
    end
    describe "items" do
      before :each do
        @from = create(:customer)
        @to = create(:customer)
        @random_purchaser = create(:customer)
        @o1 = create(:completed_order, :vouchers_count => 2, :contains_donation => true,
          :customer => @from, :purchaser => @random_purchaser)
        @o2 = create(:completed_order, :vouchers_count => 1, :contains_donation => false,
          :customer => @to, :purchaser => @to)
        @from.merge_automatically!(@to)
        @from.reload
      end
      it 'preserves donations and vouchers' do
        expect(@from.orders.count).to eq(2)
        expect(@from.vouchers.count).to eq(3)
        expect(@from.donations.count).to eq(1)
      end
      it 'preserves separate purchaser if purchaser still exists' do
        expect(@o1.purchaser).to eq(@random_purchaser)
      end
      it 'merges purchaser if same as owner' do
        @o2.reload
        expect(@o2.purchaser).to eq(@from)
      end
    end
    it 'moves labels' do
      from = create(:customer) ; to = create(:customer)
      from.labels << (l1 = create(:label))
      to.labels <<  (l2 = create(:label)) ; to.labels <<  (l3 = create(:label))
      from.merge_automatically!(to)
      new_labels = from.reload.labels
      expect(new_labels).to include(l1)
      expect(new_labels).to include(l2)
      expect(new_labels).to include(l3)
    end
    describe "successfully" do
      it "should keep password based on most recent" do
        @old.update_attributes!(:password => 'olderpass', :password_confirmation => 'olderpass')
        @new.update_attributes!(:password => 'newerpass', :password_confirmation => 'newerpass')
        salt = @new.salt
        pass = @new.crypted_password
        expect(@old.merge_automatically!(@new)).not_to be_nil
        @old.reload
        expect(@old.crypted_password).to eq(@old.encrypt('newerpass'))
        expect(@old.salt).to eq(salt)
        expect(@old.crypted_password).to eq(pass)
      end
      it "should delete the redundant customer" do
        expect(@old.merge_automatically!(@new)).not_to be_nil
        expect(Customer.find_by_id(@new.id)).to be_nil
        expect(Customer.find_by_id(@old.id)).to be_a(Customer)
      end
    end
    describe "unsuccessfully", :no_txn => true do
      before(:each) do
        @new.first_name = ''
        expect(@new).not_to be_valid
      end
      it "should add the errors to the first customer" do
        expect(@old.merge_automatically!(@new)).to be_nil
        expect(@old.errors.full_messages).not_to be_empty
      end
      it "should not delete the redundant customer" do
        expect(@old.merge_automatically!(@new)).to be_nil
        expect(Customer.find_by_id(@new.id)).to be_a(Customer)
      end
      it "should not modify the merge target" do
        expect { @premerge = Customer.find(@old.id) }.not_to raise_error
        expect(@old.merge_automatically!(@new)).to be_nil
        expect(Customer.find(@premerge.id)).to eq(@premerge)
        # Customer.columns.each do |c|
        #   col = c.name.to_sym
        #   @old.send(col).should == @old_clone.send(col) 
        # end
      end
      it "should not destroy the merge source" do
        expect(@old.merge_automatically!(@new)).to be_nil
        expect { @new = Customer.find(@new.id) }.not_to raise_error
      end
    end
  end
end
