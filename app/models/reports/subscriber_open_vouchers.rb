class SubscriberOpenVouchers < Report

  attr_accessor :open_vouchertypes

  def initialize
    @view_params = {
      :name => "Open vouchers report",
      :vouchertypes => Vouchertype.find_products(:type => :bundled_voucher,:for_purchase_by => :boxoffice)
    }
    super
  end

  def generate(params = [])
    @errors = "Please specify one or more subscriber voucher types." and return if
      (vouchertypes = params[:vouchertypes]).blank?
    vouchertypes.reject! { |x| x.to_i < 1 }
    @customers = Customer.find_by_sql %{
        SELECT DISTINCT c.*
        FROM customers c JOIN vouchers v ON v.customer_id = c.id
        WHERE v.showdate_id =0
        AND v.vouchertype_id IN (#{vouchertypes.join(',')})
}
  end

end
