class CreditCardSalesReport

  attr_reader :from, :to, :account_code_groups, :total
  
  def initialize(from,to)
    @from,@to = from,to
  end

  def run
    items =
      Item.
      joins(:order).where('orders.sold_on' => @from..@to).
      includes(:account_code,
      :order,
      :vouchertype,
      :showdate => :show).
      where('amount > 0').
      where('orders.purchasemethod' => Purchasemethod.get_type_by_name(:web_cc))
    @account_code_groups = items.group_by(&:account_code).sort
    @total = items.map(&:amount).sum
    self
  end
  
end
