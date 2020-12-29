require 'rails_helper'

describe 'TodayTix parser' do
  before(:each) do
    @dir = "#{TEST_FILES_DIR}/today_tix"
  end
  def parser_for(file)
    @import = TicketSalesImport.new(:vendor => "TodayTix", :raw_data => IO.read("#{@dir}/#{file}"))
    @parser = TicketSalesImportParser::TodayTix.new(@import)      
  end
  context  "with invalid CSV file" do
    it "should raise error if file is blank" do
      expect(parser_for "empty.csv").not_to be_valid
      expect(@import.errors[:base]).to include_match_for(/file is empty/i)
    end
    it "should raise error if headers is missing critical columns" do
      expect(parser_for "invalid_missing_required_columns.csv").not_to be_valid
      expect(@import.errors[:base]).to include('Required column(s) Order #, # of Seats, Performance Date are missing on row 0')
    end
    it "should raise error if row data has blank order number (not missing)" do
      expect(parser_for "various_errors.csv").not_to be_valid
      expect(@import.errors[:base]).to include("some required columns are blank on row 2")
    end
    it "should raise error if row data has invalid email" do
      expect(parser_for "various_errors.csv").not_to be_valid
      expect(@import.errors[:base]).to include("Email is invalid on row 3") 
    end
    it "should raise error if row data has invalid performance date" do
      expect(parser_for "various_errors.csv").not_to be_valid
      expect(@import.errors[:base]).to include("Performance Date is invalid on row 4") 
    end
  end
  context "with valid CSV file" do
    it "should return true if all rows are valid" do
      expect(parser_for "valid.csv").to be_valid
    end
  end
end
