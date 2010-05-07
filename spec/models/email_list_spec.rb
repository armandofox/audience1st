require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include BasicModels

class Customer
  def to_mailchimp
    {:FNAME => self.first_name, :LNAME => self.last_name, :email => self.email }
  end
  def ==(other)
    other.kind_of?(Customer) &&
      Customer.content_columns.map(&:name).all? { |c| self.send(c) == other.send(c) }
  end
end

describe EmailList do
  before(:each) do
    EmailList.stub!(:init_hominid).and_return(true)
  end
  describe "bulk comparison" do
    before(:each) do
      @l1 = BasicModels::create_customer_by_name_and_email %w[John Doe john@doe.com]
      @l2 = BasicModels::create_customer_by_name_and_email %w[Bob Smith bob@smith.com]
      @l3 = BasicModels::create_customer_by_name_and_email %w[Jimbo Jones jimbo@jones.com]
      @l4 = BasicModels::create_customer_by_name_and_email %w[James Jones jimbo2@jones.com]
      @l4.update_attribute(:e_blacklist, true)
      @r5 = Customer.new(:first_name => "Carl", :last_name => "Carlson", :email =>"c@carl.com")
      EmailList.stub!(:members).with('subscribed').and_return([@l1,@l2,@r5].map(&:to_mailchimp))
      @both,@remote_only,@local_only = EmailList.bulk_compare
    end
    it "should report customers that exist in both lists" do
      @both.should include(@l1)
      @both.should include(@l2)
      @both.should_not include(@r5)
      @both.should_not include(@l3)
    end
    it "should report customers that exist local but not remote" do
      @local_only.should include(@l3)
      @local_only.should_not include(@r5)
    end
    it "should report customers that exist remote but not local" do
      @remote_only.should include(@r5)
      @remote_only.should_not include(@l2)
    end
    it "should not report local customers who have opted out" do
      @local_only.should_not include(@l4)
    end
  end
end

