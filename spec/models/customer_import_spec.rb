require 'spec_helper'
include ImportTestHelper

describe CustomerImport do

  before(:all) do
    @testfiles_dir = File.join(RAILS_ROOT, 'spec', 'import_test_files', 'customer_list')
    @file_with_2_customers = File.join(@testfiles_dir, 'list_with_2_customers.csv')
    @file_with_errors = File.join(@testfiles_dir, 'list_with_2_customers.csv')
  end
  
  it "should register its type" do
    Import.import_types["Customer/mailing list"].should == "CustomerImport"
  end
  describe "preview" do
    describe "of file with CSV formatting error at row 1" do
      before(:all) do
        @import = CustomerImport.new.pretend_uploaded(@file_with_errors)
      end
      it "should have no records" do
        @import.preview.should be_empty
      end
      it "should produce an error message" do
        @import.errors.full_messages.should include "CSV file format is invalid starting at row 1"
      end
    end
    describe "for file containing 2 customers" do
      before(:all) do 
        @import = CustomerImport.new
        @import.stub!(:uploaded_data).and_return(IO.read(@file_with_2_customers))
      end
      it "should have 2 records" do
        @import.preview.should have(2).records
      end
    end
  end
end
