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

    if vouchertypes.empty?
      then flash[:notice] = "message"
    else @relation = Customer.purchased_any_vouchertypes(vouchertypes) 
    end 
    # @relation = 
    #   if vouchertypes.empty? 
    #   # then Customer.purchased_any_vouchertypes(Vouchertype.subscription_vouchertypes.map(&:id))
    #   then
    #   else 
    #   end
  end
end

