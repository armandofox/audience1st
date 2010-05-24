require 'spec_helper'
include ImportTestHelper

describe CustomerImport do

  before(:all) do
    @testfiles_dir = File.join(RAILS_ROOT, 'spec', 'import_test_files', 'customer_list')
    @file_with_2_customers = File.join(@testfiles_dir, 'list_with_2_customers.csv')
    @file_with_errors = File.join(@testfiles_dir, '..', 'invalid_files', 'file_with_csv_format_errors.csv')
  end
  
  it "should register its type" do
    Import.import_types["Customer/mailing list"].should == "CustomerImport"
  end

  it "should create a new instance given valid attributes" do
    @valid_attributes = {
      :name => "value for name",
      :completed => false,
      :number_of_records => 1,
      :filename => "value for filename",
      :content_type => "text/csv",
      :size => 1_000_000
    }
    CustomerImport.create!(@valid_attributes)
  end
  
  describe "preview" do
    describe "of file with CSV formatting error at row 1" do
      before(:all) do
        @import = CustomerImport.new
        @import.stub!(:public_filename).and_return @file_with_errors
      end
      it "should have no records" do
        @import.preview.should be_empty
      end
      it "should produce an error message" do
        @import.errors.full_messages.should include_match_for(/invalid starting at row 1/)
      end
    end
    describe "for file containing 2 valid customers plus header row" do
      before(:each) do 
        @import = CustomerImport.new
        @import.stub!(:public_filename).and_return @file_with_2_customers
      end
      it "should have 2 records" do
        @import.preview.should have(2).records
      end
      it "should not count header line in total number of records" do
        @import.num_records.should == 2
      end
      it "should have Customers as the records" do
        @import.preview[0].should be_a_kind_of(Customer)
      end
    end
  end
end
