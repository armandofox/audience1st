require 'spec_helper'

describe CustomerImport do
  it "should register its type" do
    Import.import_types["Customer/mailing list"].should == "CustomerImport"
  end
  describe "preview" do
    
  end
end
