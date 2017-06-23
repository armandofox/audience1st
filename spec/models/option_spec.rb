require 'rails_helper'

describe Option do
  before :each do
    @o = Option.first 
    @o.subscription_order_service_charge_description = ''
  end
  it 'is invalid if availability grades are not monotonically increasing' do
    cases = {
      [30,80,95] => true,
      [70,70,100] => false,
      [0, 30, 100] => false,
      [50,80,110] => false
    }
    cases.each_pair do |c,result|
      @o.limited_availability_threshold = c[0]
      @o.nearly_sold_out_threshold = c[1]
      @o.sold_out_threshold = c[2]
      !!@o.valid?.should == result
    end
  end
  it 'is invalid if service charge > 0 but no description' do
    @o.subscription_order_service_charge = 2.50
    @o.should_not be_valid
    @o.errors[:subscription_order_service_charge_description].should == "can't be blank"
  end
  it 'is valid if service charge = 0 and no description' do
    @o.subscription_order_service_charge = 0
    @o.should be_valid
  end
end
