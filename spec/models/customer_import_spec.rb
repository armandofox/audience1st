require 'rails_helper'

describe CustomerImport do

  before(:all) do
    @testfiles_dir = File.join(Rails.root, 'spec', 'import_test_files', 'customer_list')
    @file_with_2_customers = File.join(@testfiles_dir, 'list_with_2_customers.csv')
    @file_with_errors = File.join(@testfiles_dir, '..', 'invalid_files', 'file_with_csv_format_errors.csv')
  end
  
  it "should register its type" do
    Import.import_types["Customer/mailing list"].should == "CustomerImport"
  end

  it "should create a new instance given valid attributes" do
    @valid_attributes = {
      :name => "value for name",
      :filename => "value for filename",
      :content_type => "text/csv",
      :size => 1_000_000
    }
    CustomerImport.create!(@valid_attributes)
  end
  
  describe "preview" do
    describe "of file with CSV formatting error at row 1" do
      before(:each) do
        @import = CustomerImport.new
        @allow(import).to_receive(:public_filename).and_return @file_with_errors
      end
      it "should have no records" do
        @import.preview.should be_empty
      end
      it "should produce an error message" do
        @import.preview
        @import.errors.full_messages.should include_match_for(/invalid starting at row 1/)
      end
    end
    describe "for file containing 2 valid customers plus header row" do
      before(:each) do 
        @import = CustomerImport.new
        @allow(import).to_receive(:public_filename).and_return @file_with_2_customers
      end
      it "should have 3 rows" do
        CustomerImport.send(:public, :csv_rows)
        @import.csv_rows.entries.length.should == 3
      end
      it "should have 2 records, not counting header line" do
        @import.preview
        @import.number_of_records.should == 2
      end
      it "should have Customers as the records" do
        @import.preview[0].should be_a_kind_of(Customer)
      end
    end
  end
  describe "importing" do
    describe "a valid customer" do
      before(:each) do
        @customer = build(:customer)
        @import = CustomerImport.new
        @allow(import).to_receive(:get_customers_to_import).and_return([@customer])
        @imports,@rejects = @import.import!
      end
      it "should be saved" do
        Customer.find_by_email(@customer.email).should be_a_kind_of(Customer)
      end
      it "should be in the imports list" do
        @imports.should include(@customer)
      end
      it "should not be in rejects list" do
        @rejects.should_not include(@customer)
      end
      it "should not have errors" do
        @customer.errors.should be_empty
      end
    end
    describe "an invalid customer" do
      before(:each) do
        @customer = build(:customer)
        @customer.last_name = '' # makes invalid
        @customer.should_not be_valid
        @import = CustomerImport.new
        @allow(import).to_receive(:get_customers_to_import).and_return([@customer])
        @imports,@rejects = @import.import!
      end
      it "should not be saved" do
        Customer.find_by_email(@customer.email).should be_nil
      end
      it "should not appear in imports list" do
        @imports.should_not include(@customer)
      end
      it "should appear in rejects list" do
        @rejects.should include(@customer)
      end
      it "should have an error message" do
        @customer.errors_on(:last_name).should include_match_for(/is too short/i)
      end
    end
  end
end
