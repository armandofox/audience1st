class AttendanceByShow < Report
  
  def initialize(output_options={})
    season = Time.now.this_season
    @view_params = {
      :name => "Attendance by show",
      :shows => Show.all.order(:opening_date),
      :vouchertypes => Vouchertype.nonbundle_vouchertypes(season) + Vouchertype.nonbundle_vouchertypes(season-1)
    }
    super
  end

  def generate(params = {})
    shows = Report.list_of_ints_from_multiselect(params[:shows])
    # do default search for OR. if it's AND, winnow the list afterward.
    shows_not = Report.list_of_ints_from_multiselect(params[:shows_not])
    vouchertypes = Report.list_of_ints_from_multiselect(params[:vouchertypes])
    add_error("Please specify one or more productions that have one or more performances.") and return if (shows.empty? && shows_not.empty?)
    if shows.empty?
      seen = Customer.all
    else
      seen = Customer.seen_any_of(shows)
      seen = seen.purchased_any_vouchertypes(vouchertypes) if params[:restrict_by_vouchertype]
    end

    seen = (seen & Customer.seen_any_of(shows_not)) if !shows_not.empty?
    @relation = seen
  end
end
