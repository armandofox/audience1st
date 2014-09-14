class TransactionDetailsReport < Ruport::Controller

  attr_accessor :from, :to, :title

  def setup
    @from,@to = options[:from], options[:to]
    conditions = ['(amount <> 0) AND (sold_on BETWEEN ? and ?)', @from, @to]
    columns = %w(sold_on amount order_id)
    include = {
      :customer       => {:only => [], :methods => [:full_name]},
      :purchasemethod => {:only => [:description]}
    }
    report = Item.report_table(:all,
      :only => columns,
      :methods => :item_description,
      :conditions => conditions,
      :include => include
      )

  end

end
