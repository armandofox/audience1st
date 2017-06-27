class SearchCustomersByLabel < Report

  def generate(params={})
    Customer.includes('labels').where('labels.id in ?', params[:labels].keys)
  end

end
