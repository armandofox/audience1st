module VouchertypesHelper

  def humanize_season(year=Time.this_season)
    Option.season_start_month >= 6  ?
    "#{year.to_i}-#{year.to_i + 1}" :
      year.to_s
  end

  def options_for_seasons_range(from=0,to=0,selected = Time.this_season)
    from,to = to,from if from > to
    now = Time.this_season
    options_for_seasons(now + from, now + to, selected.to_s)
  end

  def options_for_seasons(from,to,selected=Time.this_season)
    from,to = to,from if from > to
    list = (from..to).to_a
    options_for_select(list.map { |y| [humanize_season(y), y.to_s] }, selected.to_s)
  end

  def human_name_for_category(category)
    case category
    when 'bundle'     then 'Bundle (subscription or otherwise)'
    when 'comp'       then 'Comp (single ticket)'
    when 'subscriber' then 'Voucher included in a bundle'
    when 'revenue'    then 'Regular revenue voucher (single ticket)'
    when 'nonticket'  then 'Nonticket product'
    else '???'
    end
  end
  def categories_with_printable_names
    Vouchertype::CATEGORIES.map do |category|
      name = human_name_for_category(category)
      [name,category]
    end
  end

  def css_class_for_vouchertype(vt)
    if vt.category.to_s == 'bundle'
      # distinguish subscription vs nonsubscription
      vt.subscription? ? 'bundle-sub' : 'bundle-nonsub'
    else
      vt.category
    end
  end

end
