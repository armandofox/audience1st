class RevenueByPaymentMethodReport

  attr_reader :from, :to, :show_id, :title, :payment_types, :totals
  attr_accessor :errors
  
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
    show = Show.find(show_id)
    @title = show.name
    @from = show.opening_date
    @to = show.closing_date
    self
  end

  def run
    items =
      Item.
      joins(:order).
      includes(:order,:account_code,:customer,:vouchertype, :showdate => :show).
      where('amount != 0').
      where(:finalized => true).
      order(:sold_on)
    if show_id
      items = items.where('shows.id' => @show_id)
    elsif from
      items = items.where(:sold_on => @from..@to)
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
  
  def csv
    csv = CSV.generate(:force_quotes => true) do |csv|
      csv << [
        'Payment Type',
        'Account Code #',
        'Account Code',
        'Order date',
        'Order#',
        'Item#',
        'Show',
        'Show Date',
        'Description',
        'Customer',
        'Promo Code',
        'Amount',
        'Stripe ID',
        'Stripe Link'
      ]
      self.payment_types.each_pair do |payment_type, account_code_groups|
        account_code_groups.each do |account_code,items|
          items.each do |item|
            begin
              auth = item.order.authorization
              csv << [
                payment_type,
                account_code.code.to_s,
                account_code.name,
                item.sold_on.strftime('%Y-%m-%d %H:%M'),
                item.order_id,
                item.id,
                (item.showdate ? item.showdate.name : ''),
                (item.showdate ? item.showdate.thedate : ''),
                item.description_for_report,
                item.customer.full_name,
                item.promo_code,
                sprintf("%.02f", item.amount),
                auth,
                %Q{=HYPERLINK("https://dashboard.stripe.com/payments/#{auth}")}
                # for test mode: "dashboard.stripe.com/test/payments/#{auth}"
              ]
            rescue StandardError => e
              err = I18n.translate('reports.revenue_details.csv_error', :item => item.id, :message => e.message)
              self.errors.add(:base, err)
              Rails.logger.error(err << "\n" << e.backtrace.join("\n   "))
              return nil
            end
          end
        end
      end
    end
    csv
  end

end
