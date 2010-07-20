require 'spec_helper'
include BasicModels

describe "BPT import" do
  before :each do
    @imp = BrownPaperTicketsImport.new
    @imp.initialize_import
  end
  describe "extracting showdate" do
    before :each do
      @imp.show = Show.placeholder("Xyz")
      @row = [nil,nil,"5/21/09 20:00"]
      BrownPaperTicketsImport.send(:public, :showdate_from_row)
    end
    it "should match existing showdate if one exists" do
      showdate = mock_model(Showdate, :thedate => Time.parse("21 May 2009 8:00pm"))
      @imp.show.stub!(:showdates).and_return([showdate])
      @imp.showdate_from_row(@row).should == showdate
    end
    context "when no match" do
      before :each do
        @imp.show.showdates << mock_model(Showdate, :thedate => Time.parse("31 Dec 2015 2:00pm"))
        #@imp.show.stub!(:showdates).and_return([])
      end
      it "should create the new showdate" do
        @new_showdate = mock_model(Showdate)
        Showdate.should_receive(:placeholder).with(Time.parse(@row[2].to_s)).and_return(@new_showdate)
        @imp.showdate_from_row(@row).should == @new_showdate
      end
      it "should add the showdate to the show" do
        @new_showdate = mock_model(Showdate)
        Showdate.stub!(:placeholder).and_return(@new_showdate)
        @imp.showdate_from_row(@row)
        @imp.show.showdates.should include(@new_showdate)
      end
      it "should increment the number of created showdates" do
        @imp.created_showdates.should be_zero
        Showdate.stub!(:showdate_from_row)
        @imp.showdate_from_row(@row)
        @imp.created_showdates.should == 1
      end
    end
  end
  describe "extracting customer" do
    before :each do
      BrownPaperTicketsImport.send(:public, :customer_from_row)
    end
    context "when no unique match" do
      before :each do
        Customer.stub!(:find_unique).and_return(nil)
        @new = BasicModels.new_generic_customer
        Customer.should_receive(:new).and_return(@new)
      end
      it "should create new customer" do
        @imp.pretend = nil
        Customer.should_receive(:find_or_create!).with(@new).and_return("new")
        @imp.customer_from_row([]).should == "new"
      end
      it "should force new customer to be valid" do
        @imp.pretend = nil
        @imp.customer_from_row([]).force_valid.should be_true
      end
      it "should increment count of created customers" do
        @imp.created_customers.should be_zero
        @imp.customer_from_row([])
        @imp.created_customers.should == 1
      end
    end
    describe "extracting vouchertype" do
      before :each do
        BrownPaperTicketsImport.send(:public, :vouchertype_from_row)
        row = Array.new(20)
      end
      def make_row(name,price)
        row = Array.new(20)
        row[18],row[19] = name,price.to_s
        row
      end
      it "should return first match if more than one match" do
        v1 = BasicModels.create_revenue_vouchertype
        v1.update_attributes!(:name => "V01", :price => 11.0)
        v2 = BasicModels.create_revenue_vouchertype
        v2.update_attributes!(:name => "V01", :price => 11.0)
        @imp.vouchertype_from_row(make_row("V01", 11.0),2010).should be_a_kind_of(Vouchertype)
      end
      describe "creating vouchertype when no match" do
        it "should force the name to valid" do
          @imp.vouchertype_from_row(make_row('Xx',1),2010).should be_valid
        end
        it "should be a vouchertype" do
          @imp.vouchertype_from_row(make_row('Xx',1),2010).should be_a_kind_of(Vouchertype)
        end
        it "should instantiate a new vouchertype" do
          @imp.instance_variable_get('@created_vouchertypes').should be_zero
          @imp.vouchertype_from_row(make_row('Nonexistent',1),2010)
          @imp.instance_variable_get('@created_vouchertypes').should == 1
        end
        it "should have the correct name and price" do
          v = @imp.vouchertype_from_row(make_row('Voucher', 13.0),2010)
          v.price.should == 13
          v.name.should == 'Voucher'
        end
      end
    end
    context "in preview mode" do
      before :each do ;  @imp.pretend = true  ; end
    end
  end

end
