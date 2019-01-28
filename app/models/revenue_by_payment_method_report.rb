class RevenueByPaymentMethodReport

  attr_reader :from, :to, :payment_types, :totals
  
  def initialize(from,to)
    @from,@to = from,to
    @payment_types = {:credit_card => {}, :cash => {}, :check => {}}
    @totals = {:credit_card => {}, :cash => {}, :check => {}}
  end

  def run
    items =
      Item.
      joins(:order).where('orders.sold_on' => @from..@to).
      includes(:account_code,
      :order,
      :customer,
      :vouchertype,
      :showdate => :show).
      where('amount > 0').
      where("type != 'CanceledItem'").
      order('items.updated_at')
    payment_types = {:credit_card => :web_cc, :cash => :box_cash, :check => :box_chk}
    payment_types.each_pair do |payment_type, purchasemethod|
      results = 
        items.where('orders.purchasemethod' => Purchasemethod.get_type_by_name(purchasemethod))
      @payment_types[payment_type] = results.group_by(&:account_code).sort
      @totals[payment_type] = results.map(&:amount).sum
    end
    self
  end
  
end
