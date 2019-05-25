require 'rails_helper'

describe 'TodayTix parser' do
  describe "validating" do
    context  "invalid CSV file" do
      before(:each) do
        @import = TicketSalesImport.new(:vendor => "TodayTix", :raw_data => IO.read("spec/import_test_files/today_tix/all_in_one.csv"))
        @parser = TicketSalesImportParser::TodayTix.new(@import)
        expect(@parser).not_to be_valid
        @dir = "spec/import_test_files/today_tix"
      end
      it "should raise error if file is blank" do
        @import = TicketSalesImport.new(:vendor => "TodayTix", :raw_data => IO.read("#{@dir}/empty.csv"))
        @parser = TicketSalesImportParser::TodayTix.new(@import)
        expect(@import.errors[:base]).to include_match_for(/file is empty/i)
      end
      it "should raise error if headers is missing critical columns" do
        @import = TicketSalesImport.new(:vendor => "TodayTix", :raw_data => IO.read("#{@dir}/missing_required_columns.csv"))
        @parser = TicketSalesImportParser::TodayTix.new(@import)
        expect(@import.errors[:base]).to include_match_for(Regexp.new %Q{missing required columns: Order \#, \# of Seats},Regexp::IGNORECASE)
      end
      it "should raise error if row data has blank order number (not missing)" do
        expect(@import.errors[:base].to include("Data is invalid because Order num can't be blank on row 2"))
      end
      it "should raise error if row data has invalid email" do
        expect(@import.errors[:base]).to include("Data is invalid because Email is invalid on row 3") 
      end
      it "should raise error if row data has invalid performance date" do
        expect(@import.errors[:base]).to include("Data is invalid because Performance date is an invalid datetime on row 4") 
      end
    end
    context "valid CSV file" do
      it "should return true if all rows are valid" do
        @import = TicketSalesImport.new(:vendor => "TodayTix", :raw_data => IO.read("#{@dir}/valid.csv"))
        @parser = TicketSalesImportParser::TodayTix.new(@import)
        expect(@parser).to be_valid
      end
    end
  end
end
