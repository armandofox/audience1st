class SubscriberOpenVouchers < Report

  attr_accessor :open_vouchertypes

  def initialize(output_options={})
    @view_params = {
      :name => "Open vouchers report",
      :vouchertypes => Vouchertype.find_products(:type => :bundled_voucher,:for_purchase_by => :boxoffice)
    }
    super
  end

  def generate(params = {})
    @errors = ["Please specify one or more subscriber voucher types."] and return if
      (vouchertypes = params[:vouchertypes]).blank?
    vouchertypes = Report.list_of_ints_from_multiselect(params[:vouchertypes])
    Customer.with_open_subscriber_vouchers(vouchertypes)
  end

end
