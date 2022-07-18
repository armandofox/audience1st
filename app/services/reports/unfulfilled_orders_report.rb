class UnfulfilledOrdersReport

  require 'csv'

  attr_reader :csv, :vouchers, :unique_addresses, :empty
  
  def initialize
    @vouchers = Voucher.
      finalized.
      includes(:customer, :vouchertype, :order).
      references(:customers, :orders).
      where(:fulfillment_needed => true).
      order('customers.last_name,orders.sold_on')
    @empty = @vouchers.empty?
    @unique_addresses = @vouchers.group_by { |vc| vc.customer.street }.keys.length
  end

  def as_csv
    @csv = CSV.generate(:headers => true) do |csv|
      csv << ['First name', 'Last name', 'Email', 'Street', 'City', 'State', 'Zip',
        'Sold on', 'Quantity', 'Product']
      orders = @vouchers.group_by do |v|
        [v.ship_to, v.vouchertype]
      end
      orders.each_pair do |k,v|
        voucher = v[0]
        row = k[0].name_and_address_to_csv
        row << v[0].order.sold_on
        row << v.size           # quantity
        row << k[1].name        # product
        csv << row
      end
    end
  end
end
