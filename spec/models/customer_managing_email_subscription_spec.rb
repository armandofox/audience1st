require 'rails_helper'

describe Customer do
  describe "managing email subscriptions" do
    before(:each) do
      @customer = create(:customer)
      @email = @customer.email
    end
    context "when changing name only" do
      it "should be updated with new name even if email doesn't change" do
        @customer.update_attributes!(:e_blacklist => false)
        @customer.first_name = "Newfirstname"
        expect(EmailList).to receive(:update).with(@customer, @email)
        @customer.save!
      end
      it "should not be updated if previously opted out" do
        @customer.update_attributes!(:e_blacklist => true)
        @customer.first_name = "Newfirstname"
        expect(EmailList).not_to receive(:update)
        @customer.save!
      end
      it "should not be updated if now opting out" do
        @customer.update_attributes!(:e_blacklist => false)
        @customer.first_name = "Newfirstname"
        @customer.e_blacklist = true
        expect(EmailList).not_to receive(:update)
        @customer.save!
      end
    end
    context "when opting out" do
      before(:each) do
        @customer = create(:customer)
        @customer.update_attributes!(:e_blacklist => false)
        @email = @customer.email
        @customer.e_blacklist = true # so it's marked dirty
      end
      it "should be unsubscribed using old email" do
        expect(@customer.email_changed?).to be_falsy
        expect(EmailList).to receive(:unsubscribe).with(@customer,@email)
        @customer.save!
      end
      it "should be unsubscribed using old email even if email changed" do
        @customer.email = "newjohn@doe.com"
        expect(@customer.email_changed?).to be_truthy
        expect(EmailList).to receive(:unsubscribe).with(@customer,@email)
        @customer.save!
      end
    end
    context "when opting in" do
      before(:each) do
        @customer = create(:customer)
        @customer.update_attributes!(:e_blacklist => true)
        @email = @customer.email
      end
      it "with new email address should be updated to new if old address was nonblank" do
        @customer.e_blacklist = false
        @customer.email = "newjohn@doe.com"
        expect(EmailList).to receive(:update).with(@customer, @email)
        @customer.save!
      end
      it "should be subscribed with new email if old email was blank" do
        @customer.e_blacklist = false
        expect(EmailList).to receive(:subscribe).with(@customer)
        @customer.save!
      end
      it "with same email address should be subscribed with new email" do
        @customer.e_blacklist = false
        expect(EmailList).to receive(:subscribe).with(@customer)
        @customer.save!
      end
    end
  end
end
