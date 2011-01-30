class AccountingReport < Ruport::Controller

  include ApplicationHelper
  attr_accessor :from, :to, :title

  stage :itemized_groups, :subtotal_by_purchasemethod

  def setup
    @from,@to = options[:from],options[:to]
    options[:title] = "Categorized revenue #{humanize_date_range(@from,@to)}"
    @exclude_purchasemethods = Purchasemethod.find_all_by_nonrevenue(true).map(&:id)
    @exclude_categories = [:comp,:subscriber]
    @report = self.generate()
    @report.reorder("description", "code", "name", "show_name", "num_units", "total_amount")
    cols = @report.column_names
    newcols = cols.map { |c| ActiveSupport::Inflector.titleize(c) }
    @report.rename_columns(cols, newcols)
    self.data = Grouping(@report, :by => 'Description')
  end

  formatter :html do
    def html_table
      "\n<table class='hilite revenue_report'>\n" << yield << "</table>"
    end
    build :itemized_groups do
      output << "<h1>#{options[:title]}</h1>"
      output << data.to_html(:style => :justified)
    end
    build :subtotal_by_purchasemethod do
      g = data.summary('Description',
        'Subtotals' => lambda { |g| g.sigma('Total Amount') },
        :order => ['Description', 'Subtotals'])
      output << "\n<h1>Subtotals by payment type</h1>\n"
      output << g.to_html
    end
  end

  formatter :csv do
    build :itemized_groups do
      output << data.to_csv
    end
    build :subtotal_by_purchasemethods do
    end
  end

  formatter :pdf do
    build :itemized_groups do
      pad(10) { add_text options[:title] }
      draw_table data
    end
    build :subtotal_by_purchasemethods do
    end
  end
  
  protected
  
  def generate
    q = <<EOQ1
        SELECT purchasemethods.description,
               account_codes.code,
               account_codes.name,
               shows.name AS show_name,
               COUNT(*) as num_units,
               SUM(vouchertypes.price) AS total_amount
        FROM vouchers
          LEFT OUTER JOIN purchasemethods ON vouchers.purchasemethod_id=purchasemethods.id
          LEFT OUTER JOIN vouchertypes ON vouchers.vouchertype_id=vouchertypes.id
          LEFT OUTER JOIN account_codes ON vouchertypes.account_code_id=account_codes.id
          LEFT OUTER JOIN showdates ON showdates.id=vouchers.showdate_id
          LEFT OUTER JOIN shows ON shows.id=showdates.show_id
        WHERE
          vouchers.sold_on BETWEEN ? AND ?
          AND vouchers.category  NOT IN (?)
          AND vouchers.purchasemethod_id  NOT IN (?)
          AND vouchertypes.price != 0
        GROUP BY purchasemethods.description, account_codes.code, show_name
        ORDER BY account_codes.code,shows.opening_date
EOQ1
    sql = [q, @from, @to, @exclude_categories, @exclude_purchasemethods]
    Voucher.report_table_by_sql(sql)
  end

  def generate2
    includes = [:purchasemethod, :vouchertype]
    #:vouchertype => {:only => [:name, :price]},
     # :showdate  => {:only => [:show_name]},
    #}
    methods = [:account_code_reportable, :voucher_description, :purchasemethod_reportable]
    # conditions:
    #  exclude zero-cost vouchertypes (comps and bundle components)
    #  exclude walkup sales (or break out as box_cash, box_cc, etc)
    
    Voucher.report_table(:all,
      :conditions => [
        "vouchers.sold_on BETWEEN ? AND ?  AND vouchers.purchasemethod_id NOT IN (?)  AND vouchertypes.category NOT IN  (?)",
        @from, @to,
        @exclude_purchasemethods,
        @exclude_categories],
      :only => [:purchasemethod_reportable, 'count(*)', 'sum(vouchertypes.price)'],
      :methods => methods,
      :include => includes)
  end
  
end
