class AttendanceByShow < Report

  def initialize(output_options={})
    @view_params = {
      :name => "Attendance by show",
      :shows => Show.find(:all, :order => :opening_date)
    }
    super
  end

  def generate(params = {})
    shows = (params[:shows] || '').split(',').map(&:to_i).reject(&:zero?)
    # do default search for OR. if it's AND, winnow the list afterward.
    shows_not = (params[:shows_not] || '').split(',').map(&:to_i).reject(&:zero?)
    if (shows.empty? && shows_not.empty?)
      add_error "Please specify one or more productions that have one or more performances."
      return nil
    end
    seen = if shows.empty? then Customer.all else Customer.seen_any_of(shows) end
    not_seen = if shows_not.empty? then [] else Customer.seen_none_of(shows_not) end
    return seen & not_seen
  end
end
