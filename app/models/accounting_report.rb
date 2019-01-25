class AccountingReport

  attr_reader :from, :to, :credit_card, :cash, :check
  
  def initialize(from,to)
    @from,@to = from,to
  end

  def run
    items =
      Item.
      joins(:order).where('orders.sold_on' => @from..@to).
      includes(:vouchertype, :showdate => :show)
    @credit_card = items.where('orders.purchasemethod' => Purchasemethod.get_type_by_name(:web_cc)).
      group_by(&:account_code)
    self
  end
  
end
