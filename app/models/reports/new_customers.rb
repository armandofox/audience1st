class NewCustomers < Report

  def initialize(options={})
    super
  end

  def generate(params={})
    from,to = Time.range_from_params(params[:new_customer_dates])
    conds = 'created_at BETWEEN ? AND ?'
    conds << " AND email LIKE '%@%'" if params[:require_valid_email]
    conds << ' AND street IS NOT NULL' if params[:require_valid_address]
    Customer.find(:all, :conditions => [conds, from, to], :order => 'created_at')
  end

end
