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
      if vouchertypes.empty? || vouchertypes == "all"
      then Customer.purchased_any_vouchertypes(Vouchertype.subscription_vouchertypes.map(&:id))
      else Customer.purchased_any_vouchertypes(vouchertype) #TODO: handle multiple selections
      end
  end
end

