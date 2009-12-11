class BulkMailingList < Report

  def remove_dup_addresses(arr)
    # remove duplicate addresses - based on case-insensitive match of street, whitespace squeezed
    # TBD this should be done with Array.uniq
    hshtemp = Hash.new
    arr.each_index do |i|
      canonical = arr[i].street.downcase.tr_s(' ', ' ')
      if hshtemp.has_key?(canonical)
        arr.delete_at(i)
      else
        hshtemp[canonical] = true
      end
    end
  end

  def generate(params = [])
    order_by = (params[:sort_by_zip] ? 'zip, last_name' : 'last_name, zip')
    if params[:subscribers_only]
      c = Customer.find_all_subscribers(order_by,
                                        :exclude_blacklist => params[:exclude_blacklist],
                                        :exclude_e_blacklist => params[:exclude_e_blacklist])
    else
      conds = []
      conds.push('blacklist=0 OR blacklist IS NULL') if
        params[:exclude_blacklist]
      conds.push('e_blacklist=0 OR e_blacklist IS NULL') if
        params[:exclude_e_blacklist]
      conds.push('1') if conds.empty?
      c = Customer.find(:all,
                        :conditions => conds.map { |s| "(#{s})" }.join(' AND '),
                        :order => order_by)
    end
    total = c.length
    # remove invalid addresses
    c.delete_if { |cst| cst.invalid_mailing_address? } if params[:filter_invalid_addresses]
    remove_dup_addresses(c) if params[:remove_dups]
    @customers = c
  end

end
