require 'spec_helper'
require 'builder'

def xml(str) ; Nokogiri::XML::Document.parse(str) ; end

describe GoldstarXmlImport do
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
  describe "getting date and time" do
    GoldstarXmlImport.send(:public, :extract_date_and_time)
    it "should raise error if no showdate" do
      @import.stub!(:xml).and_return( xml("<x></x>"))
      lambda { @import.extract_date_and_time }.should raise_error(TicketSalesImport::ImportError, /Can't find valid date and time/)
    end
    it "should raise error if no time" do
      @import.stub!(:xml).and_return xml( <<EOS1
        <willcall>
          <on-date>Thursday, April 25</on_date>
        </willcall>
EOS1
        )
      lambda { @import.extract_date_and_time }.should raise_error(TicketSalesImport::ImportError, /Can't find valid date and time/)
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
  end
end
