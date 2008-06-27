class CustomReport < ActiveRecord::Base

  def self.content_columns
    super.delete_if { |x| %w[terms conds order].include?(x.name) }
  end
  
  def initialize(str)
    @select = str || ("SELECT DISTINCT c.* FROM customers c " <<
                      "JOIN vouchers v ON  v.customer_id = c.id " <<
                      "JOIN showdates sd ON v.showdate_id = sd.id " <<
                      "JOIN shows s ON sd.show_id = s.id")
    @terms = []
    @conds = []
    @order = nil
  end

  # add various constraints to report

  def restrict_to_real_users 
    self.add_clause("c.role >= 0")
  end

  def restrict_by_date(type = :created_on, op = ">=", date = Time.now)
    self.add_clause("c.#{type.to_s} #{op.to_s} ?", date)
  end

  def restrict_has_valid_email(flag=true)
    self.add_clause(flag ? "c.login NOT LIKE '%%@%%%%.%%'" :
                    "c.login LIKE '%%@%%%%.%%'")
  end

  def restrict_has_valid_address(flag=true)
    self.add_clause(flag ? "c.street IS NOT NULL AND c.street != ''" :
                    "c.street IS NULL OR c.street = ''")
  end

  def restrict_by_shows(flag=:seen, shows = [])
    return if shows.empty?
    if flag == :seen
      self.add_clause("v.showdate_id > 0 AND (" <<
                      shows.map { |s| "s.id = #{s.to_i}" }.join(" OR ") <<
                      ")")
    else
      raise "Can't restrict by shows NOT seen (yet)"
    end
  end

  def restrict_by_vouchers(vouchertypes = [])
    unless vouchertypes.empty?
      self.add_clause("v.showdate_id = 0 AND (" <<
                      vouchertypes.map { |v| "v.vouchertype_id = #{v.to_i}" }.join(" OR ") <<
                      ")")
    end
  end
  
  def order_by(what)
    @order = what.to_s
  end

  def sql_for_find
    sql = "#{@select}\n  WHERE " << @terms.map { |t| "(#{t})" }.join(" AND ")
    sql << " ORDER BY #{@order}" if @order
    return [sql] + @conds
  end
  
  def render_sql
    sql = "#{@select}<br/>  WHERE " <<
      Customer.render_sql([@terms.map { |t| "(#{t})" }.join("<br/>   AND ")] <<
                          "<br/>  " << @conds)
    sql << " ORDER BY #{@order}" if @order
    # just a wrapper around ActiveRecord::Base.sanitize_sql
    sql
  end

  
  private

  def add_clause(*conds)
    @terms << conds.shift
    @conds += conds
  end


end
