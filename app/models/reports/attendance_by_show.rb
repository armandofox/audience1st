class AttendanceByShow < Report
  
  def initialize(output_options={})
    @view_params = {
      :name => "Attendance by show",
      :shows => Show.find(:all, :order => :opening_date)
    }
    super
  end

  def generate(params = {})
    shows = Report.list_of_ints_from_multiselect(params[:shows])
    # do default search for OR. if it's AND, winnow the list afterward.
    shows_not = Report.list_of_ints_from_multiselect(params[:shows_not])
    if (shows.empty? && shows_not.empty?)
      add_error "Please specify one or more productions that have one or more performances."
      return nil
    end
    seen = if shows.empty? then Customer.all else Customer.seen_any_of(shows) end
    not_seen = if shows_not.empty? then [] else Customer.seen_any_of(shows_not) end
    return seen - not_seen
  end
end
