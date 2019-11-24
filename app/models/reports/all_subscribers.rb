class AllSubscribers < Report

  def initialize(output_options = {})
    @view_params = {
      :name => 'All subscribers',
      :vouchertypes => Vouchertype.subscription_vouchertypes()
    }
    super
  end

  def generate(params = {})
    add_error("Please specify one or more subscriber voucher types.") and return if (vouchertypes = params[:vouchertypes]).blank?
    vouchertypes = Report.list_of_ints_from_multiselect(params[:vouchertypes])
    @relation = Customer.purchased_any_vouchertypes(vouchertypes) 
  end
end

