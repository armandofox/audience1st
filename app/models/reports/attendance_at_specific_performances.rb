class AttendanceAtSpecificPerformances < Report
  include ActionView::Helpers::FormOptionsHelper
  include ActionView::Helpers::JavaScriptHelper
  def initialize(output_options={})
    current_show = Showdate.current_or_next.try(:show)
    shows = Show.for_seasons(Time.this_season-2, Time.this_season+1)
    shows_showdates =
      Hash[shows.map { |s| [s.id.to_s, escape_javascript(options_from_collection_for_select(s.showdates, :id, :printable_date))] }].
      to_json
    @view_params = {
      :name => "Attendance at specific performances",
      :shows => shows,
      :current_show => current_show,
      :shows_showdates => shows_showdates.html_safe
    }
    super
  end

  def generate(params = {})
    add_error("Please select a valid show date.") and return unless
      showdate = Showdate.find_by_id(params[:attendance_showdate_id])
    @relation = showdate.customers
  end
end
