class QueryBuilder

  def initialize(str)
    @select = str
    @terms = []
    @conds = []
    @order = nil
  end

  def add_clause(*conds)
    @terms << conds.shift
    @conds += conds
  end

  def order_by(what)
    @order = what.to_s
  end

  def sql_for_find
    sql = "#{@select} WHERE " << @terms.map { |t| "(#{t})" }.join(" AND ")
    sql << " ORDER BY #{@order}" if @order
    return [sql] + @conds
  end
  
  def render_sql
    Customer.render_sql([@terms.map { |t| "(#{t})" }.join(" AND ")] +@conds)
    # just a wrapper around ActiveRecord::Base.sanitize_sql
  end
  
end
