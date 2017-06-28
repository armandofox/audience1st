require 'rails_helper'
require 'fakeweb'

@@testdir = "#{Rails.root}/spec/import_test_files/goldstar_auto_importer"

def parse_file(f)
  TMail::Mail.parse(IO.read(File.join(@@testdir,f)))
end


describe GoldstarAutoImporter do
  before(:each) do
    skip
    @testdir = "#{Rails.root}/spec/import_test_files/goldstar_auto_importer"
    @e = GoldstarAutoImporter.new
    ActionMailer::Base.deliveries = []
    FakeWeb.allow_net_connect = false
    FakeWeb.clean_registry
  end
  after(:all) do
    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry
  end
  describe "prechecks" do
    it "should raise error if email is not a will-call" do
      @e.email = parse_file("sales_update.eml")
      @e.execute!.should be_nil
      @e.messages.should include_match_for(/ignored/i)
    end
    it "should raise error if email is not from goldstar.com" do
      @e.email = parse_file("not_from_goldstar.eml")
      @e.execute!.should be_nil
      @e.messages.should include_match_for(/someone@somewhere-else.com/)
    end
    it "should raise error if XML URL not found" do
      @e.email = parse_file("bad_url.eml")
      @e.execute!.should be_nil
      @e.messages.should include_match_for(/will-call url for xml not found/i)
    end
    it "should raise error if XML is malformed" do
      @e.email = parse_file("valid.eml")
      allow(@e).to receive(:fetch_xml).and_return("This is not valid XML")
      @e.execute!.should be_nil
      @e.messages.should include_match_for(/malformed xml/i)
    end
    it "should get through prep step with no errors if happy path" do
      @e.email = parse_file("valid.eml")
      allow(@e).to receive(:fetch_xml).and_return(IO.read(File.join("#{Rails.root}/spec/import_test_files/goldstar_xml/goldstar-valid.xml")))
      GoldstarAutoImporter.send(:public, :prepare_import)
      lambda { @e.prepare_import }.should_not raise_error
      @e.messages.should be_empty
    end
  end
  describe "fetching" do
    before(:each) do
      @url = 'http://www.goldstar.com/valid.xml'
      @e.email = parse_file("valid.eml")
    end
    it "should raise error if XML can't be fetched" do
      FakeWeb.register_uri(:get, @url, {:status => ['404', 'Not Found'], :body => 'Not found'})
      @e.execute!.should be_nil
      @e.messages.should include_match_for(/couldn't retrieve xml/i)
      @e.messages.should include_match_for(/HTTP error 404/i)
    end
    it "should follow a redirect" do
      FakeWeb.register_uri(:get, @url,
        [{:status => "302", :body => "Redirected", :location => @url},
          {:status => "200", :body => IO.read("#{@@testdir}/valid-xml.xml")}])
      lambda { @e.prepare_import }.should_not raise_error
      @e.messages.should be_empty
    end
    it "should raise error if too many redirects" do
      FakeWeb.register_uri(:get, @url,
        :status => '302', :body => 'Redirected', :location => @url)
      @e.execute!.should be_nil
      @e.messages.should include_match_for(/too many HTTP redirects/i)
    end
    it "should succeed if happy path" do
      FakeWeb.register_uri(:get,@url,:body => IO.read("#{@@testdir}/valid-xml.xml"))
      lambda { @e.prepare_import }.should_not raise_error
      @e.messages.should be_empty
    end
  end
end


      
  
