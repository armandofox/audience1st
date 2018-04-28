class NewCustomers < Report

  def initialize(options={})
    super
  end

  def generate(params={})
    from,to = Time.range_from_params(params[:new_customer_dates])
    @relation = Customer.where(:created_at => from..to)
  end

end
