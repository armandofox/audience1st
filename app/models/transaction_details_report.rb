class TransactionDetailsReport < Ruport::Controller

  attr_accessor :from, :to, :title
  attr_reader :report

  def setup
    @from,@to = options.from, options.to
    @report = generate()
    self.data = ''
  end

  # def generate
  #   @from,@to = options[:from], options[:to]
  #   conditions = ['(amount <> 0) AND (sold_on BETWEEN ? and ?)', @from, @to]
  #   columns = %w(sold_on order_id)
  #   # :BUG: 79120590 'amount' should be pulled from column, not computed via delegate method (see bug 79120088)
  #   computed_columns = %w(amount item_description)
  #   include = {
  #     :order          => {},
  #     :customer       => {:only => [], :methods => [:full_name]},
  #     :purchasemethod => {:only => [:description]}
  #   }
  #   report = Item.report_table(:all,
  #     :group => :order_id,
  #     :only => columns,
  #     :methods => :item_description,
  #     :conditions => conditions,
  #     :include => include
  #     )
  # end


  def generate
    # select only purchasemethods web_cc, box_cc, box_cash, box_chk.
    # eventually purchasemethods table will go away and this can be replaced
    # with a simple string match
    conditions = [
      '(purchasemethod_id IN (1,3,4,5) AND sold_on BETWEEN ? AND ?)', @from, @to]
    columns = %w(id sold_on )
    computed_columns = [:purchasemethod_description, :total]
    include = {
      # :BUG: 79120590 'amount' should be pulled from column, not computed via delegate:
      :items =>  {:only => [], :methods => %w(amount item_description)},
      # should be
      #  :items =>  {:only => %w(amount), :methods => %w(item_description)}
    }
    orders = Order.report_table(:all,
      :group => :id,
      :conditions => conditions,
      :only => columns,
      :methods => computed_columns,
      :include => include
      )
    # :BUG: 79120590
    orders = orders.sub_table { |t| t.total > 0 }
  end
end
