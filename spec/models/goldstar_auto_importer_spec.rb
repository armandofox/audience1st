require 'spec_helper'

def parse_file(f)
  TMail::Mail.parse(IO.read(File.join(@testdir, f)))
end

describe GoldstarAutoImporter do
  before(:each) do
    @testdir = "#{RAILS_ROOT}/spec/import_test_files/goldstar_auto_importer"
    @e = GoldstarAutoImporter.new
    ActionMailer::Base.deliveries = []
  end
  describe "prechecks" do
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
  end
end


      
  
