require 'rails_helper'

describe VoucherInstantiator do
  describe 'creates a simple voucher' do
    before(:each) do
      @v = create(:revenue_vouchertype)
      @vouchers = VoucherInstantiator.new(@v, promo_code: 'xyz').from_vouchertype
    end
    specify 'correctly' do
      expect(@vouchers.length).to eq(1)
    end
    specify 'with correct promo code' do
      expect(@vouchers.first.promo_code).to eq('xyz')
    end
    specify 'with other correct attributes' do
      %w(fulfillment_needed account_code).each do |attr|
        expect(@vouchers.first.send attr).to eq(@v.send attr)
      end
      expect(@vouchers.first.amount).to eq(@v.price)
    end
  end
  it 'creates multiple simple vouchers' do
    @vouchers = VoucherInstantiator.new(create(:revenue_vouchertype)).from_vouchertype(3)
    expect(@vouchers.length).to eq(3)
  end
  describe 'creating bundle' do
    before(:each) do
      @v1,@v2 = Array.new(2) { create(:vouchertype_included_in_bundle) }
      @v = create(:bundle, :including => {@v1 => 2, @v2 => 1})
      @vouchers = VoucherInstantiator.new(@v).from_vouchertype
    end
    it 'includes bundle constituents' do
      expect(@vouchers.length).to eq(4)
    end
    it 'links to children in bundle' do
      expect(@vouchers.first.bundled_vouchers.length).to eq(3)
    end
    it 'includes correct voucher types' do
      expect(@vouchers.first.bundled_vouchers).to have_vouchers_matching(quantity=2, :vouchertype_id => @v1.id)
      expect(@vouchers.first.bundled_vouchers).to have_vouchers_matching(quantity=1, :vouchertype_id => @v2.id)
    end
  end
  describe 'creating 3 bundles' do
    before(:each) do
      @v1,@v2 = Array.new(2) { create(:vouchertype_included_in_bundle) }
      @v = create(:bundle, :including => {@v1 => 2, @v2 => 1})
      @vouchers = VoucherInstantiator.new(@v).from_vouchertype(3)
    end
    it 'creates all the vouchers' do
      expect(@vouchers.size).to eq(12) # 3 bundles, + 3 tix per bundle
    end
    it 'links to parents' do
      (0..2).each do |bundle|
        expect(@vouchers[bundle*4].bundled_vouchers.size).to eq(3)
      end
    end
    it 'has correct voucher types' do
      @vouchers.values_at(0,4,8).each do |parent|
        expect(parent.bundled_vouchers).to have_vouchers_matching(quantity=2, :vouchertype_id => @v1.id)
        expect(parent.bundled_vouchers).to have_vouchers_matching(quantity=1, :vouchertype_id => @v2.id)
      end
    end
  end
end
    
