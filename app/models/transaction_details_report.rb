class TransactionDetailsReport < Ruport::Controller

  attr_accessor :from, :to, :title
  attr_reader :report

  def setup
    @from,@to = options.from, options.to
    @report = generate()
  end

  def generate
    conditions = ['(amount <> 0) AND (sold_on BETWEEN ? and ?)', @from, @to]
    columns = %w(sold_on amount order_id)
    include = {
      :customer       => {:only => [], :methods => [:full_name]},
      :purchasemethod => {:only => [:description]}
    }
    debugger
    @report = Item.report_table(:all,
      :only => columns,
      :methods => :item_description,
      :conditions => conditions,
      :include => include
      )
  end
end
