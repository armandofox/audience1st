class AttendanceByShow < Report

  def initialize
    @view_params = {
      :name => "Attendance by show",
      :shows => Show.find(:all, :order => :opening_date)
    }
  end

  def generate(params = [])
    if (shows = params[:shows]).blank?
      shows = []
    else
      shows.map! { |s| s.to_i }.reject { |s| s.zero? }
    end
    # do default search for OR. if it's AND, winnow the list afterward.
    if (shows_not = params[:shows_not]).blank?
      shows_not = []
    else
      shows_not.map! { |s| s.to_i }.reject { |s| s.zero? }
    end
    showdates = Showdate.find_all_by_show_id(shows).map { |s| s.id }
    showdates_not = Showdate.find_all_by_show_id(shows_not).map { |s| s.id }
    if (showdates.empty? && showdates_not.empty?)
      @errors = "Please specify one or more productions that have one or more performances."
      @customers = []
      return
    end
    query_template = %{
         SELECT DISTINCT c.*
         FROM customers c LEFT OUTER JOIN vouchers v ON v.customer_id = c.id
         WHERE v.showdate_id IN (%s)
         AND (c.e_blacklist = 0 OR c.e_blacklist IS NULL)
         ORDER BY c.last_name, c.first_name
}
    if showdates_not.empty?
      @customers = Customer.find_by_sql(query_template % showdates.join(','))
    elsif showdates.empty?
      @customers = Customer.find(:all) - Customer.find_by_sql(query_template % showdates_not.join(','))
    else
      @customers = Customer.find_by_sql(query_template % showdates.join(',')) -
        Customer.find_by_sql(query_template % showdates_not.join(','))
    end
  end

end
