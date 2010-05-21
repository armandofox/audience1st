require 'spec_helper'

describe Import do
  before(:each) do
    @valid_attributes = {
      :name => "value for name",
      :completed => false,
      :type => "value for type",
      :number_of_records => 1,
      :filename => "value for filename",
      :content_type => "text/csv",
      :size => 1_000_000
    }
  end

  it "should create a new instance given valid attributes" do
    Import.create!(@valid_attributes)
  end
end
