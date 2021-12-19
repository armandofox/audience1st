class SearchCustomersByLabel < Report

  def generate(params={})
    @relation = params[:labels] ?
    Customer.regular_customers.includes('labels').references(:labels).
      where('labels.id in (?)', (params[:labels] || {}).keys) :
      Customer.none
  end

end
