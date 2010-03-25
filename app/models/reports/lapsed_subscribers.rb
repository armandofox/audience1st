class LapsedSubscribers < Report

  def initialize(output_options = {})
    sub_vouchers =  Vouchertype.find_products :type => :subscription, :ignore_cutoff => true
    @view_params = {
      :have_vouchertypes => sub_vouchers,
      :dont_have_vouchertypes => sub_vouchers
    }
    super
  end

  def generate(params=[])
    have = (params[:have_vouchertypes] ||= []).reject { |x| x.to_i < 1 }
    have_not = (params[:dont_have_vouchertypes] ||= []).reject { |x| x.to_i < 1 }
    unless have.size > 0 && have_not.size > 0
      add_error "You  must specify at least one type of voucher from each list."
      return nil
    end
    self.output_options = params[:output]
    # first find customers who have ANY of the given vouchertypes
    self.add_constraint('vouchertype.id IN (?)', have)
    customers = self.execute_query
    unless have_not.empty?
      # now identify those who ALSO have ANY of the new vouchertypes, and
      # subtract the sets
      prev_subscribers = Report.new(params[:output])
      prev_subscribers.add_constraint('vouchertype.id IN (?)', have_not)
      customers -= prev_subscribers.execute_query
    end
    customers
  end
end
