require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminContentHelper do
  it "should be able to inspect if current user is an admin" do
    lambda { helper.privileged_content_for(:boxoffice) do
        "foo"
      end
    }.should_not raise_error
  end
  it "should yield content if privilege level is the same or higher"  do
    helper.stub(:current_admin).and_return(mock_model(Customer, :is_boxoffice => true))
    (helper.privileged_content_for :boxoffice do ; "content" ; end).should == "content"
  end
  it "should yield nothing if privilege level is lower" do
    helper.stub(:current_admin).and_return(mock_model(Customer, :is_boxoffice => nil))
    (helper.privileged_content_for :boxoffice do ; "content" ; end).should be_nil
  end
  it "should yield nothing if privilege level is invalid" do
    helper.stub(:current_admin).and_return(mock_model(Customer))
    (helper.privileged_content_for :boxoffice do ; "content" ; end).should be_nil
  end
end
