class NewCustomers < Report

  def initialize(options={})
  end

  def generate(params=[])
    from = Time.from_param(params[:newFrom])
    to = Time.from_param(params[:newTo])
    from,to = to,from if from > to
    conds = 'created_at BETWEEN ? AND ?'
    conds << " AND email LIKE '%@%'" if params[:require_valid_email]
    conds << ' AND street IS NOT NULL' if params[:require_valid_address]
    @customers = Customer.find(:all, :conditions => [conds, from, to],
                               :order => 'created_at')
  end

end
