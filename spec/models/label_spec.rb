require 'spec_helper'

describe Label do
  before(:each) do
    @foo_label = Label.create!(:name => "foo")
    @c = create(:customer)
  end
  describe "when valid" do
    it "should be unique" do
      lambda { Label.create!(:name => "Foo") }.should raise_error(ActiveRecord::RecordInvalid)
    end
    it "should not be empty" do
      lambda { Label.create!(:name => "") }.should raise_error(ActiveRecord::RecordInvalid)
    end
  end
  describe "when deleted" do
    it "should no longer be attached to any customer" do
      @c.labels << @foo_label
      @c.save!
      @foo_label.destroy
      @c.labels.should_not include(@foo_label)
    end
  end
  describe "when customer changes" do
    before(:each) do
      @c.labels << @foo_label
      @c.save!
    end      
    it "should be deleted when that customer is forgotten" do
      @c.forget!.should be_true
      @foo_label.customers.should_not include(@c)
    end
    it "should be deleted when that customer is expunged" do
      @c.expunge!.should be_true
      @foo_label.customers.should_not include(@c)
    end
    it "should be moved to surviving customer if merged" do
      @c2 = create(:customer)
      @c2.merge_automatically!(@c).should be_true
      @foo_label.customers.should_not include(@c)
      @foo_label.customers.should include(@c2)
    end
  end
end
