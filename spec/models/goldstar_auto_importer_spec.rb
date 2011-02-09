require 'spec_helper'

def parse_file(f)
  TMail::Mail.parse(IO.read(File.join("#{RAILS_ROOT}/spec/import_test_files/goldstar_auto_importer", f)))
end


describe GoldstarAutoImporter do
  before(:each) do
    @testdir = "#{RAILS_ROOT}/spec/import_test_files/goldstar_auto_importer"
    @e = GoldstarAutoImporter.new
    ActionMailer::Base.deliveries = []
  end
  describe "prechecks" do
    it "should raise error if email is not a will-call" do
      @e.email = parse_file("sales_update.eml")
      @e.execute!.should be_nil
      @e.errors.should include_match_for(/ignored/i)
    end
    it "should raise error if email is not from goldstar.com" do
      @e.email = parse_file("not_from_goldstar.eml")
      @e.execute!.should be_nil
      @e.errors.should include_match_for(/someone@somewhere-else.com/)
    end
    it "should raise error if XML URL not found" do
      @e.email = parse_file("bad_url.eml")
      @e.execute!.should be_nil
      @e.errors.should include_match_for(/will-call url for xml not found/i)
    end
    it "should raise error if XML is malformed" do
      @e.email = parse_file("valid.eml")
      @e.stub!(:fetch_xml).and_return("This is not valid XML")
      @e.execute!.should be_nil
      @e.errors.should include_match_for(/malformed xml/i)
    end
    it "should get through prep step with no errors if happy path" do
      @e.email = parse_file("valid.eml")
      @e.stub!(:fetch_xml).and_return(IO.read(File.join("#{RAILS_ROOT}/spec/import_test_files/goldstar_xml/goldstar-valid.xml")))
      GoldstarAutoImporter.send(:public, :prepare_import)
      lambda { @e.prepare_import }.should_not raise_error
      @e.errors.should be_empty
    end
  end
end


      
  
