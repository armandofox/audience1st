require 'spec_helper'

describe AdminContentHelper do
  it "should be able to inspect if current user is an admin" do
    lambda { helper.privileged_content_for(:boxoffice) do
        "foo"
      end
    }.should_not raise_error
  end
  context "when privilege level is high enough" do
    before :each do
      helper.stub(:current_user).and_return(mock_model(Customer, :is_boxoffice => true))
    end
    it "yields content if viewing as admin" do
      assigns[:gAdminDisplay] = true
      (helper.privileged_content_for :boxoffice do ; "content" ; end).should == "content"
    end
    it "yields nothing if viewing as patron" do
      assigns[:gAdminDisplay] = false
      (helper.privileged_content_for :boxoffice do ; "content" ; end).should be_nil
    end
  end
  it "should yield nothing if privilege level is lower" do
    helper.stub(:current_user).and_return(mock_model(Customer, :is_boxoffice => nil))
    (helper.privileged_content_for :boxoffice do ; "content" ; end).should be_nil
  end
  it "should yield nothing if privilege level is invalid" do
    helper.stub(:current_user).and_return(mock_model(Customer))
    (helper.privileged_content_for :boxoffice do ; "content" ; end).should be_nil
  end
end
