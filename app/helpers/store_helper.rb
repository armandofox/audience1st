module StoreHelper

  def options_for_credit_card
    opts = [['Visa', 'visa'], ['MasterCard','master'], ['Discover','discover']]
    opts << ['AmEx', 'american_express'] unless Option.value(:accept_amex).to_i.zero?
    opts
  end

  def options_with_default(default_item, collection, name=nil)
    name ||= collection.empty? ? '' : collection.first.class.name.humanize
    choose = default_item ? "" :
      options_for_select({"Select #{name}..." => 0})
    return choose +
      options_from_collection_for_select(collection, :id, :menu_selection_name,
                                         (default_item ? default_item.id : 0))
  end

  def ticket_menus(avs)
    min_tix = 0
    avs.each do |av|
      vid = av.vouchertype.id
      max_tix = [av.howmany, 30].min
      qty = (min_tix..max_tix).to_a
      yield vid, av.vouchertype.name_with_price, qty, av.vouchertype.price
    end
  end

  def watch_show_and_showdate_fields
    s = "\n"
    s << observe_field('show',
                         :update => :ticket_menus_inner,
                         :with => 'show_id',
                         :before => "Element.show('wait_show')",
                         :complete => 'recalc_total()',
                         :url => {:controller => 'store',
                           :action => :show_changed})
    s << "\n"
    s << observe_field('showdate',
                       :update => :ticket_menus_inner,
                       :with => 'showdate_id',
                       :before => "Element.show('wait_showdate')",
                       :complete => 'recalc_total()',
                       :url => {:controller => 'store',
                         :action => :showdate_changed})
    s
  end

  def watch_comment_field
    observe_field('comments',
                  :with => 'comment',
                  :url => {:controller => :store, :action => :comment_changed})
  end

end
