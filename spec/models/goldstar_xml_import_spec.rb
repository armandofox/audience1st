require 'spec_helper'
require 'builder'

def xml(str) ; Nokogiri::XML::Document.parse(str) ; end

describe GoldstarXmlImport do
  describe "valid import" do
    before(:each) do
      @import = GoldstarXmlImport.new
      @import.stub!(:public_filename).and_return(File.join(TEST_FILES_DIR,
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
        @import = GoldstarXmlImport.new
        @offers = xml(<<EOSoffers)
          <offers type="array">
            <offer>
              <offer-id type="integer">603630</offer-id>
              <our-price type="decimal">11.0</our-price>
              <full-price type="decimal">22.0</full-price>
              <name>General Admission</name>
            </offer>
            <offer>
              <offer-id type="integer">603640</offer-id>
              <our-price type="decimal">0.0</our-price>
              <full-price type="decimal">21.0</full-price>
              <name>Comp</name>
            </offer>
          </offers>
EOSoffers
        @vt1 = BasicModels.create_revenue_vouchertype(:price => 11.0, :name => "Goldstar 1/2 price")
        @vt2 = BasicModels.create_comp_vouchertype(:name => "Goldstar Comp")
      end
      it "should parse valid offers" do
        o = @import.parse_offers(@offers)
        o['603630'].should == @vt1
        o['603640'].should == @vt2
      end
    end
    describe "parsing valid purchase" do
      before(:each) do
        @purchase = xml( <<EOSpurchase )
          <purchase>
            <note nil="true">A comment</note>
            <claims type="array">
              <claim>
                <offer-id type="integer">603630</offer-id>
                <quantity type="integer">2</quantity>
              </claim>
            </claims>
            <last-name>Gou</last-name>
            <first-name>Fay</first-name>
            <red-velvet type="boolean">true</red-velvet>
            <purchase-id type="integer">1803883</purchase-id>
          </purchase>
EOSpurchase
      end
      describe "vouchertypes" do
        before(:each) do
          GoldstarXmlImport.send(:public, :vouchertypes_from_purchase)
          @import.offers = {
            '603630' => (@v1 = mock_model(Vouchertype)),
            '603640' => (@v2 = mock_model(Vouchertype))
          }
        end
        it "should return correct vouchertypes" do
          v = @import.vouchertypes_from_purchase(@purchase)
          v[@v1].should == 2
          v.should_not have_key(@v2)
        end
        it "should barf if offer ID doesn't exist" do
          @import.offers.delete('603630')
          lambda { @import.vouchertypes_from_purchase(@purchase) }.should raise_error(TicketSalesImport::BadOrderFormat)
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
    before(:each) do ; @import = GoldstarXmlImport.new ; end
    GoldstarXmlImport.send(:public, :extract_date_and_time)
    it "should raise error if no showdate" do
      @import.stub!(:xml).and_return( xml("<x></x>"))
      lambda { @import.extract_date_and_time }.should raise_error(TicketSalesImport::DateTimeNotFound)
    end
    it "should raise error if no time" do
      @import.stub!(:xml).and_return xml( <<EOS1
        <willcall>
          <on-date>Thursday, April 25</on_date>
        </willcall>
EOS1
        )
      lambda { @import.extract_date_and_time }.should raise_error(TicketSalesImport::DateTimeNotFound)
    end
    it "should parse into a Time when time appears as child of willcall" do
      @import.stub!(:xml).and_return xml( <<EOS2
      <willcall>
        <on-date>Friday, January 21, 2011</on-date>
        <time-note>8:00 pm</time-note>
      </willcall>
EOS2
        )
      @import.extract_date_and_time.should == Time.parse("1/21/11 8:00pm")
    end
    describe "should ignore spurious Time that is a child of Inventory" do
      it "when Time appears properly" do
        @import.stub!(:xml).and_return xml( <<EOS3
      <willcall>
        <inventories>
          <inventory>
            <time-note>Saturday, January 2</time-note>
          </inventory>
        </inventories>
        <on-date>Friday, January 21, 2011</on-date>
        <time-note>8:00 pm</time-note>
      </willcall>
EOS3
          )
        @import.extract_date_and_time.should == Time.parse("1/21/11 8:00pm")
      end
      it "when Time is otherwise missing" do
        @import.stub!(:xml).and_return xml( <<EOS4
      <willcall>
        <inventories>
          <inventory>
            <time-note>Saturday, January 2</time-note>
          </inventory>
        </inventories>
        <on-date>Friday, January 21, 2011</on-date>
      </willcall>
EOS4
          )
        lambda { @import.extract_date_and_time }.should raise_error(TicketSalesImport::DateTimeNotFound)
      end
    end
  end
end
