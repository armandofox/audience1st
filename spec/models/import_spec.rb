require 'spec_helper'
include ImportTestHelper

describe Import do
  before(:all) do
    @testfiles_dir = File.join(RAILS_ROOT, 'spec', 'import_test_files')
  end
  describe "CSV reader" do
    context "for valid CSV file" do
      before(:all) do
        @csv_file_with_2_rows = File.join(@testfiles_dir,
          'customer_list', 'list_with_2_customers.csv')
      end
      it "should be valid" do
        @import = Import.new
        @import.stub!(:public_filename).and_return(@csv_file_with_2_rows)
        @import.csv_rows.should be_a_kind_of(CSV::Reader)
      end
    end
  end
end
