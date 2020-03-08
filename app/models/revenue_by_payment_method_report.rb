class RevenueByPaymentMethodReport

  attr_reader :from, :to, :show_id, :title, :payment_types, :totals
  
  def initialize
    @errors = ActiveModel::Errors.new(self)
    @show_id = nil
    @from = @to = nil
    @header = ''
    @payment_types = {:credit_card => {}, :cash => {}, :check => {}}
    @totals = {:credit_card => {}, :cash => {}, :check => {}}
  end

  def by_dates(from,to)
    @from,@to = from,to
    @title = "#{@from.to_formatted_s(:filename)} to #{@to.to_formatted_s(:filename)}"
    self
  end

  def by_show_id(show_id)
    @show_id = show_id
    @title = Show.find(show_id).name
    self
  end

  def run
    items =
      Item.
      joins(:order).
      includes(:account_code,
      :order,
      :customer,
      :vouchertype,
      :showdate => :show).
      where('amount > 0').
      where(:finalized => true).
      where("type != 'CanceledItem'").
      order('items.updated_at')
    if show_id
      items = items.where('shows.id' => @show_id)
    elsif from
      items = items.where('orders.sold_on' => @from..@to)
    else
      self.errors.add(:base, 'You must specify either a date range or a production.')
      return nil
    end
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
