class SearchCustomersByLabel < Report

  def generate(params={})
    Customer.all(:include => 'labels', :conditions => ['labels.id in (?)', params[:labels].keys])
  end

end
