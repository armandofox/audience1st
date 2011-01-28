class AccountingReport

  attr_accessor :from, :to, :title, :report, :groups
  
  # CREDIT CARD REVENUE:
  # AccCode		 	Show/Event	Units		Subtotal
  # -----------------------------------------------------------------
  # 4100		Spalding Gray		200		$4500.00
  # 		Book of Liz		250		$4800.00
  # 4200		Donations (Gen Fund)	  8		$ 850.00
  # 		Donations (Capital Fund)  2		$ 500.00
  # 4300		Acting is fun, dammit	 10		$2000.00
  # (none) 	Intro to Directing	  6		$1200.00

  def initialize(from,to)
    @from,@to = from,to
    @title = "Revenue by category: #{@from.to_formatted_s(:month_day_year)} - #{to.to_formatted_s(:month_day_year)}"
    self.generate
  end

  def generate
    exclude_purchasemethods =
      %w(bundle none in_kind).map { |t| Purchasemethod.find_by_shortdesc(t).id }
    exclude_categories = [:comp,:subscriber]
    q = <<EOQ1
        SELECT purchasemethods.description, account_codes.code, account_codes.name, shows.name, COUNT(*) as num_units, SUM(vouchertypes.price) AS total_amount
        FROM vouchers
          INNER JOIN purchasemethods ON vouchers.purchasemethod_id=purchasemethods.id
          INNER JOIN vouchertypes ON vouchers.vouchertype_id=vouchertypes.id
          INNER JOIN account_codes ON vouchertypes.account_code_id=account_codes.id
          INNER JOIN showdates ON showdates.id=vouchers.showdate_id
          INNER JOIN shows ON shows.id=showdates.show_id
        WHERE
          vouchers.sold_on BETWEEN ? AND ?
          AND vouchers.category  NOT IN (?)
          AND vouchers.purchasemethod_id  NOT IN (?)
        GROUP BY purchasemethods.description, account_codes.code, shows.name
EOQ1
    sql = [q, @from, @to, exclude_categories, exclude_purchasemethods]
    @report = Voucher.report_table_by_sql(sql)
    @groups = Grouping(@report, :by => 'description')
  end

  def generate2
    exclude_purchasemethods =
      %w(bundle none in_kind).map { |t| Purchasemethod.find_by_shortdesc(t).id }
    exclude_categories = [:comp,:subscriber]
    includes = {
      :vouchertype => {:only => [:name, :price]},
      :showdate  => {:only => [:show_name]},
    }
    methods = [:account_code_reportable, :show_name, :purchasemethod_reportable]
    # conditions:
    #  exclude zero-cost vouchertypes (comps and bundle components)
    #  exclude walkup sales (or break out as box_cash, box_cc, etc)
    
    report =
      Voucher.report_table(:all,
      :conditions => [
        "vouchers.sold_on BETWEEN ? AND ?  AND vouchers.purchasemethod_id NOT IN (?)  AND vouchertypes.category NOT IN  (?)",
        @from, @to,
        exclude_purchasemethods,
        exclude_categories],
      :only => [:purchasemethod_reportable, 'count(*)', 'sum(vouchertypes.price)'],
      :methods => methods,
      :include => includes,
      :group => "vouchers.purchasemethod_id, vouchertypes.account_code_id, showdates.show_id")
    report
  end
 
end
