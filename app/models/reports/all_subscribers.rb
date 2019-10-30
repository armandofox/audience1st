class AllSubscribers < Report

  def initialize(output_options = {})
    @view_params = {
      :name => 'All subscribers',
      :vouchertypes => Vouchertype.subscription_vouchertypes()
    }
    super
  end

  def generate(params = {})
    vouchertypes = Report.list_of_ints_from_multiselect(params[:vouchertypes]) # From app/models/reports/subscriber_open_vouchers.rb
    puts vouchertypes
    @relation = 
      if vouchertypes.empty? # TODO: add an "all_sub" option, returns all subscription_vouchertypes
      then Customer.purchased_any_vouchertypes(Vouchertype.subscription_vouchertypes.map(&:id))
      else 
        #TODO: make use of list_of_ints_from_multiselect(), and modify app/views/reports/special/_all_subscribers.html.haml to match the list_of_ints_from_multiselect's requirement 
        Customer.purchased_any_vouchertypes(vouchertypes) #TODO: handle multiple selections
      end
  end
end

