require 'rails_helper'
require 'builder'

def xml(str) ; Nokogiri::XML::Document.parse(str) ; end
def xml_from_file(file) ; Nokogiri::XML::Document.parse(IO.read("#{Rails.root}/spec/import_test_files/goldstar_xml/#{file}.xml")) ; end

describe GoldstarXmlImport do
  before(:each) do
    pending "importing must be refactored to use Orders not Vouchers"
    @vt1 = create(:revenue_vouchertype, :price => 11.0, :name => "Goldstar 1/2 price")
    @vt2 = create(:comp_vouchertype, :name => "Goldstar Comp")
    @import = GoldstarXmlImport.new
  end
  describe "valid import" do
    before(:each) do
      @allow(import).to_receive(:public_filename).and_return(File.join(TEST_FILES_DIR,
          'goldstar_xml', 'goldstar-valid.xml'))
    end
    it "should return an XML reader object" do
      GoldstarXmlImport.send(:public, :as_xml)
      @xml = @import.as_xml
      @xml.should be_a_kind_of(Nokogiri::XML::Document)
    end
    describe "parsing offers" do
      before(:each) do
        GoldstarXmlImport.send(:public, :parse_offers)
        @offers = xml_from_file('fragments/valid-offers')
      end
      it "should parse valid offers" do
        o = @import.parse_offers(@offers)
        o['603630'].should == @vt1
        o['603640'].should == @vt2
      end
    end
    describe "parsing 2 valid purchases" do
      before(:each) do
        @purchases = xml_from_file('fragments/valid-purchase-1').xpath("/willcall/inventories/inventory/purchase")
        @purchase = @purchases[0]
      end
      it "should find 2 purchases" do ; @purchases.length.should == 2 ; end
      describe "vouchertypes" do
        before(:each) do
          GoldstarXmlImport.send(:public, :vouchertypes_from_purchase)
          @import.offers = { '603630' => @vt1, '603640' => @vt2 }
        end
        it "should return correct vouchertypes" do
          v = @import.vouchertypes_from_purchase(@purchase)
          v[@vt1].should == 2
          v.should_not have_key(@vt2)
        end
        it "should barf if offer ID doesn't exist" do
          @import.offers.delete('603630')
          lambda { @import.vouchertypes_from_purchase(@purchase) }.
            should raise_error(TicketSalesImport::BadOrderFormat)
        end
      end
      it "should parse the customer" do
        GoldstarXmlImport.send(:public, :customer_attribs_from_purchase)
        attr = @import.customer_attribs_from_purchase(@purchase)
        attr[:first_name].should == 'Fay'
        attr[:last_name].should == 'Gou'
      end
      it "should parse the comment" do
        GoldstarXmlImport.send(:public, :comment_from_purchase)
        @import.comment_from_purchase(@purchase).should == 'A comment'
      end
      it "should parse the purchase ID" do
        GoldstarXmlImport.send(:public, :purchase_id)
        @import.purchase_id(@purchase).should == '1803883'
      end
    end
  end
  describe "getting date and time" do
    GoldstarXmlImport.send(:public, :extract_date_and_time)
    it "should raise error if no showdate" do
      @allow(import).to_receive(:xml).and_return( xml("<x></x>"))
      lambda { @import.extract_date_and_time }.should raise_error(TicketSalesImport::DateTimeNotFound)
    end
    it "should raise error if no time" do
      @allow(import).to_receive(:xml).and_return xml( <<EOS1
        <willcall>
          <on_date>Thursday, April 25</on_date>
        </willcall>
EOS1
        )
      lambda { @import.extract_date_and_time }.should raise_error(TicketSalesImport::DateTimeNotFound)
    end
    it "should parse into a Time when time appears as child of willcall" do
      @allow(import).to_receive(:xml).and_return xml( <<EOS2
      <willcall>
        <on_date>Friday, January 21, 2011</on_date>
        <time_note>8:00 pm</time_note>
      </willcall>
EOS2
        )
      @import.extract_date_and_time.should == Time.parse("1/21/11 8:00pm")
    end
    describe "should ignore spurious Time that is a child of Inventory" do
      it "when Time appears properly" do
        @allow(import).to_receive(:xml).and_return xml_from_file('fragments/inventory-with-time')
        @import.extract_date_and_time.should == Time.parse("1/21/11 8:00pm")
      end
      it "when Time is otherwise missing" do
        @allow(import).to_receive(:xml).and_return xml_from_file('fragments/inventory-without-time')
        lambda { @import.extract_date_and_time }.
          should raise_error(TicketSalesImport::DateTimeNotFound)
      end
    end
  end
  describe "parsing valid will-call list (without already-entered orders)" do
    before :each do
      @allow(import).to_receive(:xml).and_return(xml_from_file('goldstar-valid'))
      @allow(import).to_receive(:get_showdate).and_return(mock_model(Showdate, :show => mock_model(Show)))
      @allow(import).to_receive(:already_entered?).and_return(nil)
      GoldstarXmlImport.send(:public, :get_ticket_orders)
      @import.get_ticket_orders
    end
    it "should include 8 vouchers" do
      @import.should have(8).vouchers
    end
    it "should associate each voucher with a valid customer" do
      @import.vouchers.each do |v|
        v.customer.should be_a_kind_of(Customer)
      end
    end
    it "should give each voucher a unique external key" do
      keys = {}
      @import.vouchers.each do |v|
        keys.should_not have_key(v.external_key)
        keys[v.external_key] = 1
      end
    end
  end
end
