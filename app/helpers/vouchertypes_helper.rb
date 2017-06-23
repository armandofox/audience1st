module VouchertypesHelper

  def humanize_season(year=Time.this_season)
    Option.season_start_month >= 6  ?
    "#{year.to_i}-#{year.to_i + 1}" :
      year.to_s
  end

  def options_for_seasons_range(from=0,to=0,selected = Time.this_season)
    from,to = to,from if from > to
    now = Time.this_season
    options_for_seasons(now + from, now + to, selected)
  end

  def options_for_seasons(from,to,selected=Time.this_season)
    from,to = to,from if from > to
    list = (from..to).to_a
    options_for_select(list.map { |y| [humanize_season(y), y.to_s] }, selected.to_s)
  end

  def categories_with_printable_names
    Vouchertype::CATEGORIES.map do |category|
      name =
        case category
        when 'bundle'     then 'Bundle'
        when 'comp'       then 'Comp (single ticket)'
        when 'subscriber' then 'Single subscriber voucher'
        when 'revenue'    then 'Regular revenue voucher'
        when 'nonticket'  then 'Nonticket product'
        else '???'
        end
      [name,category]
    end
  end

end
