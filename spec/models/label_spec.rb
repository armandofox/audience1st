require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Label do
  describe "when valid" do
    it "should be unique" do
      Label.create!(:name => "Foo")
      lambda { Label.create!(:name => "Foo") }.should raise_error(ActiveRecord::RecordInvalid)
    end
    it "should not be empty" do
      lambda { Label.create!(:name => "") }.should raise_error(ActiveRecord::RecordInvalid)
    end
  end
  describe "when customer changes" do
    it "for a customer should be deleted when that customer is forgotten" do
      flunk
    end
    it "for a customer should be deleted when that customer is expunged" do
      flunk
    end
    it "for a customer should be deleted when that customer is merged" do
      flunk
    end
  end
end
