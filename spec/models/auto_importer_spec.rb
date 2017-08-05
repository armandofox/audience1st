require 'rails_helper'

def email_body ; ActionMailer::Base.deliveries[0].body ; end
def email_header(arg) ; ActionMailer::Base.deliveries[0][arg].to_s ; end

describe AutoImporter do
  describe "email template" do
    before(:each) do
      ActionMailer::Base.deliveries = []
      Option.first.update_attributes!(:venue => "Eat Cake Theater",
        :boxoffice_daemon_notify => "help@eatcake.org")
      @e = AutoImporter.new
      allow(@e).to receive(:prepare_import).and_raise("Boom!")
    end
    it "should include error messages" do
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
  describe "finalizing" do
    skip "should happen for successful import" 
    skip "should not happen for unsuccessful import" 
  end
end

