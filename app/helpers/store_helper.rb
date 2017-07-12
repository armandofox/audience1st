module StoreHelper

  def to_numeric(str)
    str.blank? ? 0 : str.to_i
  end

  def sales_banners_for(for_what,subscriber,next_season_subscriber)
    if next_season_subscriber
      option, id = 'sales_banner_for_next_season_subscribers', 'BannerNextSeasonSubscriber'
    elsif subscriber
      option, id = 'sales_banner_for_current_subscribers', 'BannerSubscriber'
    else
      option, id = 'sales_banner_for_nonsubscribers', 'BannerNonSubscriber'
    end
    prefix = if for_what == :subscription then 'subscription' else for_what.to_s.tr(' ','').underscore end
    sanitize_option_text("#{prefix}_#{option}",
      'div', :id => "#{prefix.camelize(:lower)}_#{id}", :class => 'storeBanner')
  end
      
  def options_with_default(default_item, collection, name=nil)
    name ||= collection.empty? ? '' : collection.first.class.name.humanize
    choose = default_item ? "" :
      options_for_select({"Select #{name}..." => 0})
    return (choose +
      options_from_collection_for_select(collection, :id, :menu_selection_name,
                                         (default_item ? default_item.id : 0))).html_safe
  end

  def ticket_menus(avs)
    min_tix = 0
    valid_vouchers.each do |av|
      vid = av.valid_voucher.id
      max_tix = [av.howmany, 30].min
      qty = (min_tix..max_tix).to_a
      yield vid, av.vouchertype.name_with_price, qty, av.vouchertype.price
    end
  end

end
