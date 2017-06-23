require 'rails_helper'

describe TicketSalesImport do

  describe "importing showdate" do
    before(:each) do
      TicketSalesImport.send(:public, :import_showdate)
      @imp = TicketSalesImport.new(:show => create(:show))
      @date = "Tue, Oct 31, 8:00pm"
    end
    context "when no match" do
      it "should build the new showdate" do
        @imp.import_showdate(@date)
        @imp.show.showdates.find_by_thedate(Time.parse(@date)).should_not be_nil
      end
      it "should note the created showdate" do
        l = @imp.created_showdates.length
        @imp.import_showdate(@date)
        @imp.created_showdates.length.should == l+1
      end
    end
  end

  describe "checking duplicate order" do
    before :all do ; TicketSalesImport.send(:public, :already_entered?) ; end
    before :each do
      @imp = TicketSalesImport.new(:show => mock_model(Show, :name => 'XXX'))
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

  describe "preview" do
    describe "should bail out with errors" do
      before :each do ; @imp = BrownPaperTicketsImport.new ; end
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
  
  describe "when an error happens during import or preview process" do
    before :all do
      @imp = BrownPaperTicketsImport.new(:show => mock_model(Show, :name => 'XXX'))
      allow(@imp).to_receive(:get_ticket_orders).and_raise "Error"
    end
    it "should indicate number of good records processed" do
      @imp.preview
      @imp.number_of_records.should be_a(Fixnum)
    end
  end

end
