module VouchertypesHelper

  def seasons(from=0,to=0)
    from,to = to,from if from > to
    now = Time.this_season
    list = (now+from .. now+to).to_a
    if Option.value(:season_start_month) >= 6
      options_for_select(list.map { |y| ["#{y}-#{y+1}", y] }, now)
    else
      options_for_select(list, now)
    end
  end

end
