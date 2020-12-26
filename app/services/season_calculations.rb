# Utility methods to calculate performances/productions within a season or over
# several seasons

module SeasonCalculations

  def self.seasons_range
    # earliest and latest season for which shows exist
    earliest = [
      (Showdate.order('thedate').first.thedate.this_season rescue Time.this_season),
      (Show.order('listing_date').first.this_season rescue Time.this_season)
    ].min
    latest = [
      (Showdate.order('thedate DESC').first.thedate.this_season rescue Time.this_season),
      (Show.order('listing_date DESC').first.this_season rescue Time.this_season)
    ].max
    [earliest, latest]
  end

  def self.all_shows_for_seasons(from,to) 
    beginning,ending = Time.at_beginning_of_season(from), Time.at_end_of_season(to)
    Show.
      includes(:showdates).references(:showdates).
      where('showdates.thedate BETWEEN ? AND ?', beginning, ending).
      order('showdates.thedate').
      select('DISTINCT shows.*')
  end

end
