class AllSubscribers < Report

  def initialize(output_options = {})
    @view_params = {
      :name => 'All subscribers',
      :vouchertypes => Vouchertype.subscription_vouchertypes()
    }
    super
  end

  def generate(params = {})
    #TODO: affirm filter logic. Make sure generated query matches selections.
    #TODO: maybe we can use app/views/reports/index.html.haml#line 33~38 as a reference?
    vouchertypes = Report.list_of_ints_from_multiselect(params[:vouchertypes]) # From app/models/reports/subscriber_open_vouchers.rb
    seasons = params[:seasons]
    puts vouchertypes
    @relation = 
      if vouchertypes.empty? # TODO: add an "all_sub" option, returns all subscription_vouchertypes
      then Customer.purchased_any_vouchertypes(Vouchertype.subscription_vouchertypes.map(&:id))
      else Customer.purchased_any_vouchertypes(vouchertypes)
      end
    @relation = @relation.subscriber_during seasons unless seasons.empty?
    #TODO: currently the generated resport only contains 26 consumers 
    # when using fake data, whihch is less than the "Subscription Counts" (Qty = 62).
    # Is this correct?
    #TODO: test the above query
  end
end

