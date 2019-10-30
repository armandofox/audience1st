class AllSubscribers < Report

  def initialize(output_options = {})
    @view_params = {
      :name => 'All subscribers',
      :default_voucher_type => "???"
    }
    super
  end

  def generate(params = {})
    vouchertypes = params[:vouchertypes]
    puts vouchertypes
    @relation = 
      if vouchertypes.empty?
      then Customer.purchased_any_vouchertypes(Vouchertype.subscription_vouchertypes.map(&:id))
      #else Customer.vouchertypes_by vouchertypes # TODO: impl vouchertypes_by
      else Customer.all.each do |c|
            c.role >= 0 &&
            c.vouchers.includes(:vouchertype).detect do |f| # TODO: fixthis
              f.vouchertype.subscription? && f.vouchertype.valid_now?
          end 
        end
      end
  end
end

