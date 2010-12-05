require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Label do
  before(:each) do
    @foo_label = Label.create!(:name => "foo")
  end
  describe "when valid" do
    it "should be unique" do
      lambda { Label.create!(:name => "Foo") }.should raise_error(ActiveRecord::RecordInvalid)
    end
    it "should not be empty" do
      lambda { Label.create!(:name => "") }.should raise_error(ActiveRecord::RecordInvalid)
    end
  end
  describe "when customer changes" do
    before(:each) do
      @c = BasicModels.create_generic_customer
      @c.labels << @foo_label
      @c.save!
    end      
    it "for a customer should be deleted when that customer is forgotten" do
      @c.forget!.should be_true
      @foo_label.customers.should_not include(@c)
    end
    it "for a customer should be deleted when that customer is expunged" do
      @c.expunge!.should be_true
      @foo_label.customers.should_not include(@c)
    end
    it "for a customer should be moved to surviving customer if merged" do
      @c2 = BasicModels.create_generic_customer
      @c2.merge_automatically!(@c).should be_true
      @foo_label.customers.should_not include(@c)
      @foo_label.customers.should include(@c2)
    end
  end
end
