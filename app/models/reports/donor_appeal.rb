class DonorAppeal < Report

  def initialize(options={})
    @view_params = {
      :name => "Donor appeal"
    }
  end

  def generate(params={})
    # if subscribers included, need to join to vouchertypes table
    joins = 'customers c LEFT OUTER JOIN donations d ON d.customer_id = c.id '
    from = Time.from_param(params[:newFrom])
    to = Time.from_param(params[:newTo])
    from,to = to,from if from > to
    where = " d.amount >= #{params[:donation_amount].to_f} " <<
      " AND (d.date BETWEEN '#{from.to_formatted_s(:db)}' AND '#{to.to_formatted_s(:db)}') "
    # require valid address and/or valid email
    (where << " AND (c.email IS NOT NULL AND c.email != '') ") if params[:require_valid_email]
    (where << " AND c.street IS NOT NULL ") if params[:require_valid_address]
    # to include subscribers, join with vouchertypes table and
    # allow a match even if no donation.
    if params[:include_subscribers]
      joins << ' JOIN vouchers v on v.customer_id = c.id ' <<
        'JOIN vouchertypes vt on v.vouchertype_id = vt.id '
      from = Time.now.at_beginning_of_season.to_formatted_s(:db)
      to = Time.now.at_end_of_season.to_formatted_s(:db)
      where =
        "(#{where}) OR (vt.subscription = 1 AND
                          '#{Time.db_now}' BETWEEN '#{from}' AND '#{to}')"
    end
    sql =  <<eoq
        SELECT DISTINCT c.*
        FROM #{joins}
        WHERE #{where}
        ORDER BY c.last_name, c.first_name
eoq
    Customer.find_by_sql(sql)
  end
end
