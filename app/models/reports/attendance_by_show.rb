class AttendanceByShow < Report
  
  def initialize(output_options={})
    season = Time.current.this_season
    @view_params = {
      :name => "Attendance by show",
      :shows => Show.all.order('listing_date DESC'),
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

    # Start by restricting by vouchertype, if needed.
    if params[:restrict_by_vouchertype]
      @relation = Customer.purchased_any_vouchertypes(vouchertypes)
    else
      @relation = Customer
    end
    # for efficiency, handle the 3 cases separately:
    #  1- customers who have seen X
    #  2- customers who have not seen Y
    #  3- customers who have seen X AND have not seen Y

    if    ! shows.empty? && shows_not.empty? # case 1
      @relation = @relation.seen_any_of(shows)
    elsif shows.empty?   && ! shows_not.empty? # case 2
      @relation = @relation.seen_none_of(shows_not)
    else                        # case 3
      # make sure the same show hasn't been specified as both Seen and Not Seen
      unless (shows & shows_not).empty?
        @relation = Customer.none
        add_error "You cannot select the same show as both 'Seen' and 'Not Seen'."
      else
        @relation = @relation.seen_any_of(shows).seen_none_of(shows_not)
      end
    end
  end
end
