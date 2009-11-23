class AttendanceByShow < Report

  def initialize
    @view_params = {
      :name => "Attendance by show",
      :shows => Show.find(:all, :order => :opening_date)
    }
  end

  def generate(params = [])
    @errors = "Please specify one or more productions." and return if
      (shows = params[:shows]).blank?
    # do default search for OR. if it's AND, winnow the list afterward.
    shows.map! { |s| s.to_i }.reject { |s| s.zero? }
    showdates = Showdate.find_all_by_show_id(shows).map { |s| s.id }
    showdates_not = Showdate.find_all_by_show_id(shows_not).map { |s| s.id }
    query_template = %{
         SELECT DISTINCT c.*
         FROM customers c JOIN vouchers v ON v.customer_id = c.id
         WHERE v.showdate_id IN (%s)
         AND c.e_blacklist = 0
         ORDER BY c.last_name, c.first_name
}
    @customers = Customer.find_by_sql(query_template % showdates.join(',')) -
      Customer.find_by_sql(query_template % showdates_not.join(','))
  end

end
