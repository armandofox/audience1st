class AttendanceByShow < Report

  def initialize(output_options={})
    @view_params = {
      :name => "Attendance by show",
      :shows => Show.find(:all, :order => :opening_date)
    }
    super
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
      add_error "Please specify one or more productions that have one or more performances."
      return nil
    end
    # build query for shows ATTENDED, if needed
    if showdates.empty?
      # start with ALL customers no matter what they've seen
      seen = AttendanceByShow.new(self.output_options).execute_query
    else
      self.add_constraint('voucher.showdate_id IN (?)', showdates)
      seen = self.execute_query
    end
    if !showdates_not.empty?
      # remove customers who HAVEN'T seen these shows
      notseen = AttendanceByShow.new(self.output_options)
      notseen.add_constraint('voucher.showdate_id IN (?)', showdates_not)
      seen -= notseen.execute_query
    end
    @customers = seen
  end
end
