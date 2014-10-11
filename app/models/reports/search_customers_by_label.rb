class SearchCustomersByLabel < Report

  def generate(params={})
    Customer.all(:include => 'labels', :conditions => ['labels.id in (?)', Report.list_of_ints_from_multiselect(params[:labels])])
  end

end
