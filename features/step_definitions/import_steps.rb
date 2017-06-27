require 'fakeweb'

Given /a valid Goldstar will-call email "(.*).eml" for "(.*)" on (.*)/ do |raw_email, show, date|
  @email = IO.read("#{Rails.root}/spec/import_test_files/goldstar_auto_importer/#{raw_email}.eml")
  # by assumption the email is valid, so let's grab the XML and fake out the Web call
  url = "http://www.goldstar.com/#{raw_email}.xml"
  xmlcontent = IO.read("#{Rails.root}/spec/import_test_files/goldstar_auto_importer/#{raw_email}-xml.xml")
  FakeWeb.register_uri(:get, url, :body => xmlcontent)
end

When /^that valid email is received and processed by (.*)$/ do |klass|
  GoldstarAutoImporter.import_from_email(@email).should be_truthy
end
