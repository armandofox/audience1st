class AttendanceByShow < Report

  def initialize
    @view_params = {
      :name => "Attendance by show",
      :shows => Show.find(:all)
    }
  end

  def generate(params = [])
    @errors = "Please specify one or more productions." and return if
      (shows = params[:shows]).blank?
    # do default search for OR. if it's AND, winnow the list afterward.
    shows = Show.find_by_id(shows)
    showdates = Showdate.find(:all, :conditions => ['show_id IN (?)', shows]).map { |s| s.id }
    @customers = Customer.find_by_sql %{
         SELECT DISTINCT c.*
         FROM customers c JOIN vouchers v ON v.customer_id = c.id
         WHERE v.showdate_id IN (#{showdates.join(',')})
         ORDER BY c.last_name, c.first_name
}
    # if this is an AND query, limit to customers who have seen ALL
    # of the shows in question.
  end

end
