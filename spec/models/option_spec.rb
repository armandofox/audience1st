require 'rails_helper'

describe Option do
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
        !!(expect(@o.valid?).to eq(result))
      end
    end
    it 'is invalid if service charge > 0 but no description' do
      @o.subscription_order_service_charge = 2.50
      expect(@o).not_to be_valid
      expect(@o.errors[:subscription_order_service_charge_description]).to include "can't be blank"
    end
    it 'is valid if service charge = 0 and no description' do
      @o.subscription_order_service_charge = 0
      expect(@o).to be_valid
    end
  end
end
