require 'spec_helper'
include ImportTestHelper

describe Import do
  before(:all) do
    @testfiles_dir = File.join(RAILS_ROOT, 'spec', 'import_test_files')
  end
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
        @csv_file_with_2_rows = File.join(@testfiles_dir,
          'customer_list', 'list_with_2_customers.csv')
      end
      it "should be valid" do
        # @import = Import.new
        # @import.stub!(:uploaded_data).and_return IO.read(@csv_file_with_2_rows)
        @import = Import.new.pretend_uploaded(@csv_file_with_2_rows)
        @import.csv_rows.should be_a_kind_of(CSV::Reader), @import.errors.full_messages
      end
    end
  end
end
