require 'rails_helper'

describe "email sub" do
  # The EmailList instance can receive #subscribe, #unsubscribe, #update (change email address
  # on existing subscriber)
  def stub_list
    # this cannot be in a before-block, because if so, FactoryBot creating the customers
    # will end up triggering the double inadvertently.
    @list = double(EmailList)
    allow(EmailList).to receive(:new).and_return(@list)
  end
  context "when customer created" do
    it "subscribes customer if e_blacklist not checked" do
      @customer = build(:customer, :e_blacklist => false, :email => 'n@ai')
      stub_list
      expect(@list).to receive(:subscribe).with(@customer)
      @customer.save!
    end
    it "does not subscribe customer if e_blacklist checked" do
      @customer = build(:customer, :e_blacklist => true, :email => 'n@ai')
      stub_list
      expect(@list).not_to receive(:subscribe)
      @customer.save!
    end
  end
  context "for existing opted-in customer" do
    before(:each) do
      @customer = create(:customer, :email => 'n@ai', :e_blacklist => false)
    end
    it "should be updated with new name even if email doesn't change" do
      @customer.first_name = "Newfirstname"
      stub_list
      expect(@list).to receive(:update).with(@customer, 'n@ai')
      @customer.save!
    end
    it "should be unsubscribed if email is changed from nonblank to blank" do
      @customer.update_attribute(:created_by_admin, true) # to allow blank email
      @customer.email = ''
      stub_list
      expect(@list).to receive(:unsubscribe).with(@customer, 'n@ai')
      @customer.save!
    end
    it "should not be updated if name doesn't change" do
      @customer.street = '1 New Street'
      stub_list
      expect(@list).not_to receive(:update)
      @customer.save!
    end
    describe "transitioning to opted-out" do
      before(:each) do
        @customer.e_blacklist = true # so it's marked dirty
      end
      it "should be unsubscribed using old email" do
        expect(@customer.email_changed?).to be_falsy
        stub_list
        expect(@list).to receive(:unsubscribe).with(@customer,'n@ai')
        @customer.save!
      end
      it "should be unsubscribed using old email even if email also changed" do
        @customer.email = "newjohn@doe.com"
        expect(@customer.email_changed?).to be_truthy
        stub_list
        expect(@list).to receive(:unsubscribe).with(@customer,'n@ai')
        @customer.save!
      end
    end
  end
  context "for existing opted-out customer" do
    before(:each) do
      @customer = create(:customer, :email => 'n@ai', :e_blacklist => true)
    end
    it "should not be updated when customer info changes" do
      @customer.first_name = "Newfirstname"
      stub_list
      expect(@list).not_to receive(:update)
      @customer.save!
    end
    describe "when transitioning to opted-in" do
      before(:each) do
        @customer.e_blacklist = false
      end
      it "with new email address should be updated to new if old address was nonblank" do
        @customer.email = "newjohn@doe.com"
        stub_list
        expect(@list).to receive(:update).with(@customer, 'n@ai')
        @customer.save!
      end
      it "should be subscribed with new email if old email was blank" do
        stub_list
        expect(@list).to receive(:subscribe).with(@customer)
        @customer.save!
      end
      it "with same email address should be subscribed with new email" do
        stub_list
        expect(@list).to receive(:subscribe).with(@customer)
        @customer.save!
      end
    end
  end
end
