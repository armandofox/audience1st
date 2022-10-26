require 'rails_helper'

describe RevenueByPaymentMethodReport do
  before(:each) do
    @rev1 = create(:revenue_voucher) ; create(:order_from_vouchers, :vouchers => [@rev1])
    @comp1 = create(:comp_voucher)   ; create(:order_from_vouchers, :vouchers => [@comp1])
    @sub1 = create(:subscriber_voucher) ; create(:order_from_vouchers, :vouchers => [@sub1])
    @bun1 = create(:bundle_voucher, :including => {@sub1 => 1}) ; create(:order_from_vouchers, :vouchers => [@bun1])
  end
  describe 'contents' do
    before(:each) do
      @r = RevenueByPaymentMethodReport.new.by_dates(1.day.ago, 1.day.from_now)
      @r.run
    end
    def all_items(category)
      @r.payment_types[category].map { |arr| arr[1] }.flatten
    end
    it 'includes comps' do ;  expect(all_items(:cash)).to include(@comp1) ; end
    it 'includes revenue' do ;expect(all_items(:cash)).to include(@rev1) ; end
    it 'includes subs' do ;expect(all_items(:cash)).to include(@sub1) ; end
    it 'includes bundles' do ;expect(all_items(:cash)).to include(@bun1) ; end
  end
end
