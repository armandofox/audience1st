class SubscriberOpenVouchers < Report

  attr_accessor :open_vouchertypes

  def initialize(output_options={})
    @view_params = {
      :name => "Open vouchers report",
      :vouchertypes => Vouchertype.subscriber_vouchertypes_in_bundles
    }
    super
  end

  def generate(params = {})
    add_error("Please specify one or more subscriber voucher types.") and return if (vouchertypes = params[:vouchertypes]).blank?
    vouchertypes = Report.list_of_ints_from_multiselect(params[:vouchertypes])
    @relation = Customer.with_open_subscriber_vouchers(vouchertypes)
  end

end
