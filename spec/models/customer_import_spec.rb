require 'rails_helper'

describe CustomerImport do

  before(:all) do
    @testfiles_dir = File.join(TEST_FILES_DIR, 'customer_list')
    @file_with_2_customers = File.join(@testfiles_dir, 'list_with_2_customers.csv')
  end
  
  xit "should register its type" do
    expect(Import.import_types["Customer/mailing list"]).to eq("CustomerImport")
  end

  xit "should create a new instance given valid attributes" do
    @valid_attributes = {
      :name => "value for name",
      :filename => "value for filename",
      :content_type => "text/csv",
      :size => 1_000_000
    }
    CustomerImport.create!(@valid_attributes)
  end
  
  xdescribe "preview" do
    describe "for file containing 2 valid customers plus header row" do
      before(:each) do 
        @import = CustomerImport.new
        allow(@import).to receive(:public_filename).and_return @file_with_2_customers
      end
      it "should have 2 records, not counting header line" do
        @import.preview
        expect(@import.number_of_records).to eq(2)
      end
      it "should have Customers as the records" do
        expect(@import.preview[0]).to be_a_kind_of(Customer)
        expect(@import.preview[1]).to be_a_kind_of(Customer)
      end
    end
  end
  xdescribe "importing" do
    describe "a valid customer" do
      before(:each) do
        @customer = build(:customer)
        @import = CustomerImport.new
        allow(@import).to receive(:get_customers_to_import).and_return([@customer])
        @imports,@rejects = @import.import!
      end
      it "should be saved" do
        expect(Customer.find_by_email(@customer.email)).to be_a_kind_of(Customer)
      end
      it "should be in the imports list" do
        expect(@imports).to include(@customer)
      end
      it "should not be in rejects list" do
        expect(@rejects).not_to include(@customer)
      end
      it "should not have errors" do
        expect(@customer.errors).to be_empty
      end
    end
    describe "an invalid customer" do
      before(:each) do
        @customer = build(:customer)
        @customer.last_name = '' # makes invalid
        expect(@customer).not_to be_valid
        @import = CustomerImport.new
        allow(@import).to receive(:get_customers_to_import).and_return([@customer])
        @imports,@rejects = @import.import!
      end
      it "should not be saved" do
        expect(Customer.find_by_email(@customer.email)).to be_nil
      end
      it "should not appear in imports list" do
        expect(@imports).not_to include(@customer)
      end
      it "should appear in rejects list" do
        expect(@rejects).to include(@customer)
      end
      it "should have an error message" do
        expect(@customer.errors_on(:last_name)).to include_match_for(/is too short/i)
      end
    end
  end
end
