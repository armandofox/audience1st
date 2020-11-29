require 'rails_helper'

describe CanceledItem do
  describe 'new' do
    subject { CanceledItem.new }
    its(:amount) { should be_zero }
  end
  describe 'created from existing item' do
    subject { create(:revenue_voucher, :amount => 13).cancel!(create(:customer)) }
    its(:class) { should == CanceledItem }
    its(:amount) { should eq(13) }
  end
end
  
