class ShowAdvanceSalesReport

  attr_reader :errors, :csv

  def initialize(shows)
    @shows = shows
    @errors = ActiveModel::Errors.new(self)
    @csv = ''
  end

  def generate
    @csv = CSV.generate do |csv|
      csv << [
        'Show Name',
        'Run Dates',
        'Show Date',
        'House Capacity',
        'Max Advance Sales for Performance',
        'Voucher Type',
        'Subscriber Voucher?',
        'Max Sales for voucher type',
        'Number Sold or Reserved',
        'Price',
        'Gross Receipts'
        ]

      @shows.each do |show|
        show.showdates.each do |sd|
          vouchers = sd.vouchers.finalized
          sales = Showdate::Sales.new(vouchers.group_by(&:vouchertype), sd.revenue_per_seat, sd.total_offered_for_sale)
          sales.vouchers.each_pair do |vt,v|
            max_sales = vt.valid_vouchers.find { |v| v.showdate_id == sd.id }.max_sales_for_type
            csv << [
              show.name,
              show.run_dates,
              sd.thedate,
              sd.house_capacity,
              sd.max_advance_sales,
              vt.name,
              (if vt.subscriber_voucher? then "YES" else "" end),
              (if max_sales != ValidVoucher::INFINITE then max_sales else "" end),
              v.size,
              (sprintf "%.02f", vt.price),
              (sprintf "%.02f", vt.price * v.size)
            ]
          end
        end
      end
    end
    self
  end
  

end
