require 'rails_helper'

describe Order, 'deleting' do
  describe 'non-credit-card order' do
    before :each do
      @o = create(:order, :vouchers_count => 2, :contains_donation => true)
      @vouchers = @o.vouchers
      @donation = @o.donations.first
      @o.destroy
    end
    it 'destroys the donation' do ; Donation.find_by_id(@donation.id).should be_nil ;  end
    it 'destroys the vouchers' do ; @vouchers.any? { |v| Voucher.find_by_id(v.id) }.should be falsey ; end
    it 'should summarize prices and ids of deleted things' do
      s = @o.summary_for_audit_txn
      (@vouchers + [@donation]).each do |item|
        s.should include("[#{item.id}]")
        s.should include(sprintf("%.2f", item.amount))
      end
    end
  end
end
