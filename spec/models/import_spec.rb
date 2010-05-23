require 'spec_helper'

TESTFILES_DIR = File.join(RAILS_ROOT, 'spec', 'import_test_files')

describe Import do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :completed => false,
      :type => "CustomerImport",
      :number_of_records => 1,
      :filename => "value for filename",
      :content_type => "text/csv",
      :size => 1_000_000
    }
  end

  it "should create a new instance given valid attributes" do
    Import.create!(@valid_attributes)
  end
  describe "CSV reader" do
    context "for valid CSV file" do
      before(:all) do
        @csv_file_with_2_rows = File.join(TESTFILES_DIR,
          'customer_lists', 'list_with_2_customers.csv')
      end
      it "should be valid" do
        @import = Import.new(:uploaded_data => IO.read(@csv_file_with_2_rows),
          :null_object => true)
        rows = @import.csv_rows
        rows.should be_a_kind_of(CSV::Reader)
      end
    end
    context "for invalid file", :shared => true do
      it "should return an empty array"
      it "should add an error message"
    end
    context "when file is empty" do
      @file = File.join(TESTFILES_DIR, 'invalid_files', 'empty_file.csv')
      @error = "No data found"
      it_should_behave_like "for invalid file"
    end
    context "when file is not valid CSV" do
      @file = File.join(TESTFILES_DIR, 'invalid_files', 'not_a_csv_file.csv')
      @error = "Does not appear to be a valid CSV file"
      it_should_behave_like "for invalid file"
    end
  end
end
