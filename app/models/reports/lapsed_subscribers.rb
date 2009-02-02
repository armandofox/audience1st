class LapsedSubscribers < Report

  def initialize
    sub_vouchers =  Vouchertype.find_products :type => :subscription, :ignore_cutoff => true
    @view_params = {
      :have_vouchertypes => sub_vouchers,
      :dont_have_vouchertypes => sub_vouchers
    }
  end

  def generate(params=[])
    have = (params[:have_vouchertypes] ||= []).reject { |x| x.to_i < 1 }
    have_not = (params[:dont_have_vouchertypes] ||= []).reject { |x| x.to_i < 1 }
    unless have.size > 0 && have_not.size > 0
      @errors = "You  must specify at least one type of voucher from each list."
      return
    end
    # first find customers who have ANY of the given vouchertypes
    sql  = %{
        SELECT DISTINCT c.*
        FROM customers c JOIN vouchers v ON v.customer_id = c.id
        WHERE v.vouchertype_id IN (%s)
        ORDER BY c.last_name
        }
    prev_subscribers = Customer.find_by_sql(sprintf sql, have.join(','))
    # now identify those who ALSO have ANY of the new vouchertypes, and
    # subtract the sets
    renewed_subscribers = Customer.find_by_sql(sprintf sql, have_not.join(','))
    @customers = prev_subscribers - renewed_subscribers
  end

end
