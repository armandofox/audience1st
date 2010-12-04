require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Label do
  it "should be unique" do
    Label.create!(:name => "Foo")
    lambda { Label.create!(:name => "Foo") }.should raise_error(ActiveRecord::RecordInvalid)
  end
  it "should not be empty" do
    lambda { Label.create!(:name => "") }.should raise_error(ActiveRecord::RecordInvalid)
  end
end
