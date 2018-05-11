module ShowsHelper

  def label_for_page_header(type)
    case type
    when 'Special Event' then 'Special Events'
    when 'Class' then 'Classes & Camps'
    when 'Subscription' then 'Subscribe Now'
    else 'Shows'
    end
  end
  def label_for_event_type(type)
    case type
    when 'Special Event' then 'Event'
    when 'Class' then 'Class'
    when 'Subscription' then 'Subscription Package'
    else 'Show'
    end
  end

  def link_to_show_tickets(show)
    params = {:show_id => show.id}
    params[:what] = 'Special Events' if show.special?
    store_url(params).html_safe
  end

  def link_to_showdate_tickets(showdate, params={})
    params[:showdate_id] = showdate.id
    params[:what] = 'Special Events' if showdate.show.special?
    store_url(params).html_safe
  end

end
