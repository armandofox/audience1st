require 'spec_helper'

describe DatetimeRange do

  describe "attributes" do
    before(:each) do ;  @d = DatetimeRange.new ; end
    it "has a start date" do ;   @d.start_date.should be_a(Date)  ; end
    it "has an end date"  do ;   @d.end_date.should be_a(Date) ; end
    it "has a time" do ; @d.time.should be_a(Time) ; end
  end

end
