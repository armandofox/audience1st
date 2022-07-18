class SubscriptionSalesReport
  attr_reader :vouchers_for_display, :csv
  
  def initialize(season)
    @season = season
    @csv = nil
    @vouchers_for_display = []
  end

  # count the number of subscriptions for a given season
  def run
    season_start = Time.current.at_beginning_of_season(@season)
    v = Vouchertype.subscription_vouchertypes(@season)
    @vouchers_for_display = v.map { |t| [t.name, t.price.round, Voucher.where(:finalized => true, :vouchertype_id => t.id).count] }
    self
  end

  def generate_csv
    subs = Vouchertype.
             for_season(@season).
             of_categories('bundle').
             where(:subscription => true).
             map(&:id)

    customers = Customer.
                  unscoped.
                  joins(:vouchers => :vouchertype).
                  where('items.finalized' => true).
                  where('vouchertypes.id' => subs).
                  select('customers.*, vouchertypes.name AS vouchertype_name, vouchertypes.price AS vouchertype_price, COUNT(vouchertypes.id) AS qty').
                  order('customers.last_name,customers.id').
                  group('customers.id','vouchertypes.id')

    @csv = CSV.generate(:headers => true) do |csv|
      csv << Customer.csv_header + %w(Subscription Price Quantity)
      customers.each do |c|
        csv <<  c.to_csv + [c.vouchertype_name, sprintf('%0.2f',c.vouchertype_price), c.qty]
      end
    end
  end
end
