module VouchertypesHelper

  def humanize_season(year=Time.this_season)
    Option.value(:season_start_month) >= 6  ?
    "#{year.to_i}-#{year.to_i + 1}" :
      year.to_s
  end

  def seasons(from=0,to=0)
    from,to = to,from if from > to
    now = Time.this_season
    list = (now+from .. now+to).to_a
    options_for_select(list.map { |y| [humanize_season(y), y] }, now)
  end

end
