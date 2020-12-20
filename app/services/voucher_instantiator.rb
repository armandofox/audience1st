class VoucherInstantiator

  def initialize(vouchertype, klass: Voucher, promo_code: nil)
    @vouchertype = vouchertype
    @klass = klass
    @promo_code = promo_code
  end

  def from_vouchertype(qty = 1)
    vouchers = []
    qty.times do
      voucher = create_simple_voucher(@vouchertype)
      vouchers << voucher
      if @vouchertype.bundle?
        # add the included vouchers
        @vouchertype.included_vouchers.each_pair do |vtype_id,qty|
          vtype = Vouchertype.find vtype_id
          included_vouchers = Array.new(qty) { create_simple_voucher(vtype) }
          voucher.bundled_vouchers += included_vouchers
          vouchers += included_vouchers
        end
      end
    end
    vouchers
  end

  private

  def create_simple_voucher(vt)
    @klass.send(:new, {
        :vouchertype => vt,
        :fulfillment_needed => vt.fulfillment_needed,
        :amount => vt.price,
        :account_code => vt.account_code,
        :promo_code => @promo_code
      })
  end

end
