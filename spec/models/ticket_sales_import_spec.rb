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
        expect(@imp.show.showdates.find_by_thedate(Time.zone.parse(@date))).not_to be_nil
      end
      it "should note the created showdate" do
        l = @imp.created_showdates.length
        @imp.import_showdate(@date)
        expect(@imp.created_showdates.length).to eq(l+1)
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
      expect(Voucher).to receive(:find_by_external_key).with(@existing_order_id).
        and_return(mock_model(Voucher, :show => mock_model(Show, :name => "New")))
      expect { @imp.already_entered?(@existing_order_id) }.to raise_error(TicketSalesImport::ImportError)
    end
    it "should not raise error if already entered for same show" do
      expect(Voucher).to receive(:find_by_external_key).with(@existing_order_id).
        and_return(mock_model(Voucher, :show => @imp.show))
      expect { @imp.already_entered?(@existing_order_id) }.not_to raise_error
    end
  end

  xdescribe "preview" do
    describe "should bail out with errors" do
      before :each do ; @imp = build(:brown_paper_tickets_import) ; end
      it "if no show specified" do
        @imp.preview
        expect(@imp.errors.full_messages).to include_match_for(/show does not exist/i)
      end
      it "if nonexistent show specified" do
        @imp.show_id = 99999
        expect(Show.find_by_id(99999)).to be_nil
        @imp.preview
        expect(@imp.errors.full_messages).to include_match_for(/show does not exist/i)
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
      expect(@imp.number_of_records).to be_a(Fixnum)
    end
  end

end
