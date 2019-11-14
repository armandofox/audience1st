class AllSubscribers < Report

  def initialize(output_options = {})
    @view_params = {
      :name => 'All subscribers',
      :vouchertypes => Vouchertype.subscription_vouchertypes()
    }
    super
  end

  def generate(params = {})
    vouchertypes = Report.list_of_ints_from_multiselect(params[:vouchertypes])
    @relation = 
      if vouchertypes.empty? 
      then Customer.purchased_any_vouchertypes(Vouchertype.subscription_vouchertypes.map(&:id))
      else Customer.purchased_any_vouchertypes(vouchertypes) 
      end
  end
end

