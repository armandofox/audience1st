class AttendanceAtSpecificPerformances < Report

  def initialize(output_options={})
    current_show = Show.current_or_next
    @view_params = {
      :name => "Attendance at specific performances",
      :shows => Show.all_for_seasons(Time.this_season-2, Time.this_season+1),
      :current_show => current_show,
      :showdates => (current_show ? current_show.showdates : [])
    }
    super
  end

  def generate(params = {})
    @errors = ["Please select a valid show date."] and return unless
      showdate = Showdate.find_by_id(params[:attendance_showdate_id])
    showdate.customers
  end
end
