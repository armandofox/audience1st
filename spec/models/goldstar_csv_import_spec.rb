require 'rails_helper'

describe "Goldstar new CSV format importing" do
  before(:each) do
    pending "Importing must be refactored to use Orders, not Vouchers"
    @showdate = create(:showdate, :date => Time.at_beginning_of_season(2012) + 1.week)
    @show = @showdate.show
    @imp = GoldstarCsvImport.new(:show => @show)
  end
  def use_file(f)
    @imp.stub!(:public_filename).and_return(File.join(Rails.root, 'spec', 'import_test_files', 'goldstar_csv', f))
  end
  describe "format sanity checks" do
    it "should reject if column headers invalid" do
      use_file('no_headers.csv')
      @imp.showdate_id = create(:showdate, :date => Time.now).id
      @imp.preview
      @imp.sanity_check.should be_nil
      @imp.errors.full_messages.should include("Expected header row not found")
    end
    it "should reject if showdate invalid" do
      @imp.showdate_id = 99999
      @imp.preview ;   @imp.sanity_check.should be_nil
      @imp.errors.full_messages.should include_match_for(/invalid showdate id/i)
    end
    it "should reject if showdate null" do
      @imp.showdate_id = nil
      @imp.preview ;   @imp.sanity_check.should be_nil
      @imp.errors.full_messages.should include_match_for(/invalid showdate id/i)
    end
  end
  describe "previewing a valid file" do
    before(:each) do
      @imp.showdate_id = @showdate.id
      use_file('valid_with_halfprice_only.csv')
    end
    context "when Goldstar vouchertypes exist" do
      before(:each) do
        create(:comp_vouchertype, :name => "Goldstar Comp", :season => @show.season)
        create(:revenue_vouchertype, :name => "Goldstar Half", :season => @show.season, :price => 10)
      end
      it "should pass sanity check" do
        @imp.preview
        @imp.sanity_check.should be_true
      end
      it "should not have any already-entered records" do
        @imp.preview
        @imp.existing_vouchers.should == 0
      end
      it "should have 10 records" do
        @imp.preview
        @imp.number_of_records.should == 10
      end
      it "should have 20 vouchers" do
        @imp.preview
        @imp.should have(20).vouchers
      end
    end
    context "when Goldstar vouchertypes do not exist" do
  end
  end
end
