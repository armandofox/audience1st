require 'rails_helper'

describe Option do
  describe 'caching' do
    it 'caches option values' do
      val1 = Option.season_start_month
      Option.any_instance.stub(:season_start_month).and_raise("Option isn't caching its values")
      val2 = Option.season_start_month
      expect(val1).to eq(val2)
    end
    it 'nukes cache when options updated' do
      val1 = Option.season_start_month
      Option.update_attributes!(:season_start_month => val1+1)
      expect(val1).not_to eq(Option.season_start_month)
    end
  end
  describe 'validations' do
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
      @o.errors[:subscription_order_service_charge_description].should include "can't be blank"
    end
    it 'is valid if service charge = 0 and no description' do
      @o.subscription_order_service_charge = 0
      @o.should be_valid
    end
  end
end
