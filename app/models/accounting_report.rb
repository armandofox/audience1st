class AccountingReport

  attr_accessor :from, :to, :title
  
  # CREDIT CARD REVENUE:
  # AccCode		 	Show/Event	Units		Subtotal
  # -----------------------------------------------------------------
  # 4100		Spalding Gray		200		$4500.00
  # 		Book of Liz		250		$4800.00
  # 4200		Donations (Gen Fund)	  8		$ 850.00
  # 		Donations (Capital Fund)  2		$ 500.00
  # 4300		Acting is fun, dammit	 10		$2000.00
  # (none) 	Intro to Directing	  6		$1200.00

  @@sql_query = <<EOQ1
      SELECT v.purchasemethod_id,vt.account_code,s.name,
                SUM(vt.price) AS totalprice,COUNT(*) AS numunits
        FROM vouchers v
          INNER JOIN vouchertypes vt ON v.vouchertype_id=vt.id
          INNER JOIN showdates sd ON sd.id = v.showdate_id
          INNER JOIN shows s ON s.id = sd.show_id
        WHERE
          v.sold_on BETWEEN ? and ?
        GROUP BY v.purchasemethod_id,vt.account_code,s.name
        ORDER BY v.purchasemethod_id
EOQ1
  
  def initialize(from,to)
    @from,@to = from,to
    @title = "Revenue by category: #{@from.to_formatted_s(:month_day_year)} - #{to.to_formatted_s(:month_day_year)}"
  end

  def generate
    # five categories:
    #  subscriptions  by purchasemethod
    #  advance ticket sales by purchasemethod
    #  walkup ticket sales by purchasemethod
    #  donations by purchasemethod and donation fund
    #  everything else



    sql = [sql_query, @from, @to, Customer.walkup_customer.id]
    @show_txns = Voucher.find_by_sql(sql)
    # next, all the Bundle Vouchers - regardless of purchase method
    sql = ["SELECT vt.name,vt.account_code,SUM(vt.price) " <<
           "FROM vouchers v " <<
           "  INNER JOIN vouchertypes vt ON v.vouchertype_id = vt.id " <<
           "WHERE " <<
           " vt.price > 0" <<
           " AND (v.sold_on BETWEEN ? AND ?)" <<
           " AND v.customer_id NOT IN (0,?)" <<
           " AND vt.category='bundle'" <<
           "GROUP BY vt.account_code,vt.name",
           @from, @to, Customer.walkup_customer.id]
    @subs_txns = sort_and_filter(Voucher.find_by_sql(sql),"vt.price")
    # last, all the Donations
    sql = ["SELECT df.name,d.account_code,SUM(d.amount) " <<
           "FROM donations d, account_codes df " <<
           "WHERE d.date BETWEEN ? AND ? " <<
           "GROUP BY d.purchasemethod_id",
           @from, @to]
    @donation_txns = sort_and_filter(Voucher.find_by_sql(sql),"d.amount")
  end

end
