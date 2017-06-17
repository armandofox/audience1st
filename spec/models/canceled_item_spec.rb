require 'rails_helper'

describe CanceledItem do
  describe 'new' do
    subject { CanceledItem.new }
    its(:price) { should be_zero }
  end
  describe 'created from existing item' do
    subject { create(:revenue_voucher).cancel!(create(:customer)) }
    its(:class) { should == CanceledItem }
    its(:price) { should be_zero }
  end
end
  
