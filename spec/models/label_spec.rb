require 'rails_helper'

describe Label do
  before(:each) do
    @foo_label = Label.create!(:name => "foo")
    @c = create(:customer)
  end
  describe "when valid" do
    it "should be unique" do
      expect { Label.create!(:name => "Foo") }.to raise_error(ActiveRecord::RecordInvalid)
    end
    it "should not be empty" do
      expect { Label.create!(:name => "") }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
  describe "when deleted" do
    it "should no longer be attached to any customer" do
      @c.labels << @foo_label
      @foo_label.destroy
      @c.reload
      expect(@c.labels).not_to include(@foo_label)
    end
  end
  describe "when customer changes" do
    before(:each) do
      @c.labels << @foo_label
      @c.save!
    end      
    it "should be deleted when that customer is forgotten" do
      expect(@c.forget!).to be_truthy
      expect(@foo_label.customers).not_to include(@c)
    end
    it "should be moved to surviving customer if merged" do
      @c2 = create(:customer)
      expect(@c2.merge_automatically!(@c)).to be_truthy
      expect(@foo_label.customers).not_to include(@c)
      expect(@foo_label.customers).to include(@c2)
    end
  end
end
