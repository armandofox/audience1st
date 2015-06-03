require 'spec_helper'

describe Order, 'deleting' do
  describe 'non-credit-card order' do
    before :each do
      @o = create(:order, :vouchers_count => 2, :contains_donation => true)
      @vouchers = @o.vouchers.map(&:id)
      @donation = @o.donations.first.id
      @o.destroy
    end
    it 'destroys the donation' do ; Donation.find_by_id(@donation).should be_nil ;  end
    it 'destroys the vouchers' do ; @vouchers.any? { |v| Voucher.find_by_id(v) }.should be_false ; end
  end
end
