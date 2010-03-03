require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminContentHelper do
  it "should yield content if privilege level is the same or higher"  do
    helper.stub_chain(:controller, :current_admin).and_return(mock_model(Customer, :is_boxoffice => true))
    content = helper.content_for :boxoffice do
      "content"
    end
    content.should == "content"
  end
  it "should yield nothing if privilege level is lower" do
    helper.stub!(:current_admin).and_return(mock_model(Customer, :is_boxoffice => nil))
    content = helper.content_for :boxoffice do
      "content"
    end
    content.should be_nil
  end
  it "should yield nothing if privilege level is invalid" do
    helper.stub!(:current_admin).and_return(mock_model(Customer))
    content = helper.content_for :boxoffice do
      "content"
    end
    content.should be_nil
  end
end
