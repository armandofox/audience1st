# -*- coding: utf-8 -*-
require 'rails_helper'

describe Customer do
  it 'gets ID from route' do
    expect(Customer.id_from_route("/customers/3334")).to eq("3334")
  end
  describe "labels" do
    before(:each) do
      @c = create(:customer)
      @l1 = Label.create!(:name => "L1")
      @l2 = Label.create!(:name => "L2")
    end
    it "should update label ID's" do
      labels = [@l2.id]
      @c.set_labels(labels)
      expect(@c.labels).to include(@l2)
      expect(@c.labels).not_to include(@l1)
    end
    it "should remove labels it previously had" do
      @c.labels = [@l1]
      @c.set_labels([@l2.id])
      expect(@c.labels).not_to include(@l1)
      expect(@c.labels).to include(@l2)
    end
    it "should remove ALL labels if nothing checked" do
      @c.labels = [@l1,@l2]
      @c.set_labels(nil)
      expect(@c.labels).not_to include(@l1)
      expect(@c.labels).not_to include(@l2)
    end
    it "should not have a label after label is deleted" do
      @c.labels = [@l1, @l2] ;  @c.save!
      @l2.destroy 
      @c.reload
      expect(@c.labels).not_to include(@l2)
    end
    describe "when merging" do
      before(:each) do
        @c2 = create(:customer)
      end
      it "should keep union of labels when merging automatically" do
        @c2.labels = [@l1] ; @c2.save!
        @c.labels =  [@l2] ; @c.save!
        expect(@c.merge_automatically!(@c2)).to be_truthy
        @c.reload
        expect(@c.labels).to include(@l1)
        expect(@c.labels).to include(@l2)
      end
      it "should not barf if dupes already have overlapping label" do
        @c2.labels = [@l1] ; @c2.save!
        @c.labels  = [@l1] ; @c.save!
        expect(@c2.merge_automatically!(@c)).to be_truthy
        @c2.reload
        expect(@c2.labels).to include(@l1)
      end
      it "should move the labels to the customer surviving a merge" do
        @c2.update_labels!([@l1.id])
        expect(@c2.labels).to include(@l1)
        expect(@c.merge_automatically!(@c2)).to be_truthy
        @c.reload
        expect(@c.labels).to include(@l1)
      end
    end
  end
      
  describe "special" do
    %w[walkup_customer anonymous_customer boxoffice_daemon].each do |c|
      it "#{c.humanize} cannot be destroyed" do
        cust = Customer.send(c)
        expect { cust.destroy }.to raise_error(Customer::CannotDestroySpecialCustomersError)
      end
    end
  end
  describe "validation message" do
    it "includes first or last name if available" do
      expect(@c = Customer.new(:first_name => 'Joe')).not_to be_valid
      expect(@c.errors.full_messages).to include_match_for(/^Joe\s*:/)
    end
    it "includes ID if no name available" do
      @c = create(:customer)
      @c.last_name = @c.first_name = ''
      expect(@c).not_to be_valid
      expect(@c.errors.full_messages).to include_match_for(/^Customer ID #{@c.id}\s*: .*/)
    end
    it "includes no identifier if new record" do
      @c = build(:customer)
      @c.first_name = @c.last_name = ''
      expect(@c).not_to be_valid
      expect(@c.errors.full_messages).to include_match_for(/^New unnamed customer: .*/)
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
        expect(@customer).to be_valid
      end
      it "should not be able to do credit card purchases" do
        expect(@customer).not_to be_valid_as_purchaser
      end
      it "should not be a valid gift recipient" do
        expect(@customer).not_to be_valid_as_gift_recipient
      end
    end
    context "with nonblank address" do
      before(:each) do
        @customer = create(:customer)
      end
      it "should be valid" do
        expect(@customer).to be_valid
      end
      it "should be invalid if some address fields not filled in" do
        @customer.city = ''
        expect(@customer).not_to be_valid
      end
    end
    describe "eligible as gift recipient" do
      before(:each) do
        @customer = Customer.new(:first_name => "John", :last_name => "Doe",
          :day_phone => "555-1212",
          :eve_phone => "666-2323")
        allow(@customer).to receive(:invalid_mailing_address?).and_return(false)
        allow(@customer).to receive(:valid_email_address?).and_return(true)
      end
      it "should be valid with valid attributes" do
        expect(@customer).to be_valid_as_gift_recipient
      end
      it "should be valid even if only one phone number" do
        @customer.day_phone = nil
        expect(@customer).to be_valid_as_gift_recipient
      end
      it "should have both first and last name" do
        @customer.first_name = nil
        expect(@customer).not_to be_valid_as_gift_recipient
      end
      it "should have both first and last name, take 2" do
        @customer.last_name = nil
        expect(@customer).not_to be_valid_as_gift_recipient
      end
      it "should have a valid mailing address" do
        allow(@customer).to receive(:invalid_mailing_address?).and_return(true)
        expect(@customer).not_to be_valid_as_gift_recipient
      end
      it "should have email if no day phone or eve phone" do
        @customer.eve_phone = nil
        @customer.day_phone =  nil
        expect(@customer).to be_valid_as_gift_recipient
      end
      it "should have day phone if no email or eve phone" do
        allow(@customer).to receive(:valid_email_address?).and_return(false)
        @customer.eve_phone = nil
        expect(@customer).to be_valid_as_gift_recipient
      end
      it "should have eve phone if no email or day phone" do
        allow(@customer).to receive(:valid_email_address?).and_return(false)
        @customer.day_phone = nil
        expect(@customer).to be_valid_as_gift_recipient
      end
      it "should not be missing both phone numbers AND email" do
        @customer.day_phone = @customer.eve_phone = ''
        allow(@customer).to receive(:valid_email_address?).and_return(false)
        expect(@customer).not_to be_valid_as_gift_recipient
      end
    end
  end
  describe "determine if mailing address does not match record" do
    context "when email and last name matches" do
      before(:each) do
        @attrs = {:first_name => 'Bob', :last_name => 'Jones',
          :email => 'bobjones@mail.com',
          :street => '1234 Fake St',
          :city => 'New York', :state => 'NY', :zip => '99999'
        }
        @old = create(:customer,@attrs)
        @cust = Customer.new(@attrs)
      end
      it "returns false if address does match" do
          expect(Customer.email_last_name_match_diff_address?(@old)).to be_falsy
      end
      it "returns true if address doesn't match" do
          @cust.street = "1234 Genuine St"
          expect(Customer.email_last_name_match_diff_address?(@cust)).to be_truthy
      end
    end
  end
  describe "determine if last name does not match record" do
    context "when email matches" do
      before(:each) do
        @attrs = {:first_name => 'Bob', :last_name => 'Jones',
          :email => 'bobjones@mail.com',
          :street => '1234 Fake St',
          :city => 'New York', :state => 'NY', :zip => '99999'
        }
        @old = create(:customer,@attrs)
        @cust = Customer.new(@attrs)
      end
      it "returns false if last name does match" do
          expect(Customer.email_matches_diff_last_name?(@old)).to be_falsy
      end
      it "returns true if last name doesn't match" do
          @cust.last_name = "Thorne"
          expect(Customer.email_matches_diff_last_name?(@cust)).to be_truthy
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
        @old = create(:customer,@attrs)
        @cust = Customer.new(@attrs)
      end
      context "and last name matches" do
        it "should match without an address" do
          [:street,:city,:state,:zip].each { |e| @attrs.delete(e) }
          expect(Customer.find_unique(@cust)).to eq(@old)
        end
        it "should match even if addresses differ" do
          @cust.street = '999 New St'
          expect(Customer.find_unique(@cust)).to eq(@old)
        end
        it "should match even if first names differ" do
          @cust.first_name = 'Bill'
          expect(Customer.find_unique(@cust)).to eq(@old)
        end
      end
      context "but last name differs" do
        it "should not match if first name also differs" do
          @cust.first_name = 'Bill' ; @cust.last_name = 'Smith'
          expect(Customer.find_unique(@cust)).to be_nil
        end
      end
    end
    shared_examples "when email cannot break ties" do
      before(:each) do
        @attrs = {:first_name => 'Bob', :last_name => 'Smith',
          :street => '99 Fake Blvd', :city => 'New York',
          :state => 'NY', :zip => '99999'}
        @old = create(:customer, @attrs.merge(:email => @old_email))
        @old.update_attribute(:created_by_admin, true)
        @new = Customer.new(@attrs.merge(:email => @new_email))
        @new.created_by_admin =  true
      end
      it "should match if first, last and address all match" do
        expect(Customer.find_unique(@new)).to eq(@old)
      end
      [:first_name, :last_name, :street].each do |attr|
        it "should not match if #{attr} is blank in database" do
          @old.send("#{attr}=", nil)
          if @old.valid?
            @old.save
            expect(Customer.find_unique(@new)).to be_nil
          else
            true
          end
        end
        it "should not match if #{attr} is different in database" do
          @old.update_attribute(attr, @old.send(attr) << "XXX")
          expect(Customer.find_unique(@new)).to be_nil
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
        @old = create(:customer, :first_name => 'Joe', :last_name => 'Jones')
        expect(Customer.find_unique(Customer.new(:first_name => 'Joe', :last_name => 'Jones'))).to  eq(@old)
      end
      it "should not match if first & last match exactly but not uniquely" do
        2.times { create(:customer, :first_name => 'Joe', :last_name => 'Jones') }
        expect(Customer.find_unique(Customer.new(:first_name => 'Joe', :last_name => 'Jones'))).to be_nil
      end
    end
  end

end
