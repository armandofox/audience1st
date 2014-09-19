class TransactionDetailsReport

  attr_accessor :from, :to, :title

  def self.run(from, to)
    # select only purchasemethods web_cc, box_cc, box_cash, box_chk.
    # eventually purchasemethods table will go away and this can be replaced
    # with a simple string match
    orders = Order.report_table(:all,
      :conditions => ['(purchasemethod_id IN (1,3,4,5) AND sold_on BETWEEN ? AND ?)', from, to],
      :only => [:id, :sold_on, :authorization],
      :methods => [:purchasemethod_description, :item_descriptions, :total],
      :include => {:customer => {:only => %w(id), :methods => %w(full_name)}}
      )
    # :BUG: 79120590
    orders = orders.sub_table { |t| t.total > 0 }
    orders.reorder %w(id sold_on customer.id customer.full_name purchasemethod_description authorization total item_descriptions)
    orders.rename_columns(
      'id'                => 'Order#',
      'sold_on'           => 'Sold on',
      'customer.id'       => 'Cust#',
      'customer.full_name'=> 'Name',
      'purchasemethod_description' => 'Payment method',
      'authorization'     => 'Stripe Auth',
      'total'             => 'Total',
      'item_descriptions' => 'Items'
      )
      # %w(id sold_on customer.id customer.full_name purchasemethod_description authorization total item_descriptions),
      # ['Order#', 'Sold on', 'Cust#', 'Name', 'Payment method', 'Authorization', 'Total', 'Items'])
    orders
  end

end





