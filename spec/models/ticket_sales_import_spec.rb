require 'rails_helper'

describe TicketSalesImport do
  describe 'new' do
    it 'initializes parser' do
      @i = TicketSalesImport.new(:vendor => 'TodayTix')
      expect(@i.parser).to be_a TicketSalesImportParser::TodayTix
    end
    it 'does not choke if invalid parser' do
      expect { TicketSalesImport.new(:vendor => 'NoSuchVendor') }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'pre-finalizing' do
    it 'warns if total import quantity exceeds redemption allocation'
    it 'warns if import file contained extraneous columns'
  end

end

describe TicketSalesImport, :pending => 'refactor import logic' do

  xdescribe "importing showdate" do
    before(:each) do
      TicketSalesImport.send(:public, :import_showdate)
      @imp = build(:ticket_sales_import)
      @date = "Tue, Oct 31, 8:00pm"
    end
    context "when no match" do
      it "should build the new showdate" do
        @imp.import_showdate(@date)
        @imp.show.showdates.find_by_thedate(Time.zone.parse(@date)).should_not be_nil
      end
      it "should note the created showdate" do
        l = @imp.created_showdates.length
        @imp.import_showdate(@date)
        @imp.created_showdates.length.should == l+1
      end
    end
  end

  xdescribe "checking duplicate order" do
    before :all do ; TicketSalesImport.send(:public, :already_entered?) ; end
    before :each do
      @imp = build(:ticket_sales_import)
      @existing_order_id = '12345678'
    end
    it "should raise error if already entered for different show" do
      Voucher.should_receive(:find_by_external_key).with(@existing_order_id).
        and_return(mock_model(Voucher, :show => mock_model(Show, :name => "New")))
      lambda { @imp.already_entered?(@existing_order_id) }.should raise_error(TicketSalesImport::ImportError)
    end
    it "should not raise error if already entered for same show" do
      Voucher.should_receive(:find_by_external_key).with(@existing_order_id).
        and_return(mock_model(Voucher, :show => @imp.show))
      lambda { @imp.already_entered?(@existing_order_id) }.should_not raise_error
    end
  end

  xdescribe "preview" do
    describe "should bail out with errors" do
      before :each do ; @imp = build(:brown_paper_tickets_import) ; end
      it "if no show specified" do
        @imp.preview
        @imp.errors.full_messages.should include_match_for(/show does not exist/i)
      end
      it "if nonexistent show specified" do
        @imp.show_id = 99999
        Show.find_by_id(99999).should be_nil
        @imp.preview
        @imp.errors.full_messages.should include_match_for(/show does not exist/i)
      end
    end
  end
  
  xdescribe "when an error happens during import or preview process" do
    before :each do
      @imp = build(:brown_paper_tickets_import)
      allow(@imp).to receive(:get_ticket_orders).and_raise "Error"
    end
    it "should indicate number of good records processed" do
      @imp.preview
      @imp.number_of_records.should be_a(Fixnum)
    end
  end

end
