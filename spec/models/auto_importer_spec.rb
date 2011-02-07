require 'spec_helper'

def email_body ;  ActionMailer::Base.deliveries[0].body ; end
def email_header(arg) ; ActionMailer::Base.deliveries[0][arg].to_s ; end

describe AutoImporter do
  describe "email template" do
    before(:each) do
      ActionMailer::Base.deliveries = []
      Option.create!(:name => :venue_name, :typ => :string,
        :value => "Eat Cake Theater")
      Option.create!(:name => :boxoffice_daemon_notify, :typ => :email,
        :value => "help@eatcake.org")
      @e = AutoImporter.new
      @e.stub!(:prepare_import).and_raise("Boom!")
    end
    it "should include the error messages" do
      @e.execute!
      email_body.should include("Boom!")
    end
    it "should include the venue name" do
      @e.execute!
      email_body.should include("Eat Cake Theater")
    end
    it "should be delivered to the notification email address" do
      @e.execute!
      email_header('to').should == "help@eatcake.org"
    end
  end
end

