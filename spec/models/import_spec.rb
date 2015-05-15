require 'spec_helper'

describe Import do
  describe 'sort order' do
    it 'should sort by completed date if both completed' do
      Import.new(:completed_at => 1.day.from_now).should be > Import.new(:completed_at => Time.now)
    end
    it 'should not give a sort error for uncompleted imports' do
      Import.new(:created_at => 1.day.from_now).should be > Import.new(:created_at => Time.now)
    end
    it 'should not give a sort error for new records' do
      lambda { Import.new <=> Import.new }.should_not raise_error
    end
  end
  describe 'when finalized' do
    before :each do
      @i = BrownPaperTicketsImport.create!(:show => create(:show))
      @c = create(:customer, :role => :boxoffice)
    end
    it 'should set customer ID' do
      @i.finalize(@c)
      @i.customer.should == @c
    end
    it 'should set completion time' do
      @i.finalize(@c)
      @i.completed_at.should be_close(Time.now, 3)
    end
  end
end
