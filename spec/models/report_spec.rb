require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Report do
  describe "when created" do
    context "with no output options" do
      before(:each) do ;  @r = Report.new ;  end
      it "should return a flat query object"  do
        @r.query.should be_a(String)
      end
      it "should return a valid SQL query" do
        lambda { Customer.find_by_sql(@r.query) }.should_not raise_error
      end
    end
  end
  describe "SQL query for constraint" do
    describe "with no bind variables" do
      before(:each) do
        @r = Report.new
        @r.add_constraint('voucher.price = 1')
      end
      it "should be a flat string" do
        @r.query.should be_a(String)
      end
      it "should include JOIN with constrained table" do
        @r.query.should match(/join vouchers/i)
      end
    end
    describe "with 1 bind variable" do
      before(:each) do
        @r = Report.new
        @r.add_constraint('voucher.price > ?', 10)
      end
      it "should be an array" do
        @r.query.should be_an(Array)
      end
      it "should include JOIN with constrained table" do
        @r.query.first.should match(/join vouchers/i)
      end
    end
    describe "with 2 bind variables from table A and 1 from table B" do
      before(:all) do
        @r = Report.new
        @r.add_constraint('voucher.price BETWEEN ? AND ?', 1,10)
        @r.add_constraint('donation.created_on < ?', Time.now)
      end
      it "should include query plus 3 bind slots" do
        @r.query.should be_an(Array)
        @r.query.should have(4).elements
      end
    end
  end
end
  
    
