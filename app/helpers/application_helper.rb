# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  include ActiveSupport::Inflector # so individual views don't need to reference explicitly

  def in_rows_of(n,collection)
    return '' if (collection.nil? || collection.empty?)
    rows = ''
    collection.each_slice(n) do |things|
      row = ''
      things.each { |l|  row << content_tag('td', yield(l)) }
      rows << content_tag('tr', row.html_safe)
    end
    content_tag('table') do
      content_tag('tbody', rows.html_safe)
    end
  end

  def truncate_with_hovering(str, opts={})
    str = h(str)
    content_tag(:span, truncate(str,opts) + content_tag(:span, str),
      :class => 'tooltip') 
  end

  def render_multiline_message(m,sep="<br/>\n")
    sep = sep.html_safe
    if m.respond_to?(:errors_as_html)
      m.errors_as_html(sep).html_safe
    elsif (m.kind_of? Array)
      # each element is either a string, or something that responds
      #  to errors_as_html.  Render them recursively.
      m.map do |line|
        content_tag(:span, render_multiline_message(line,sep).html_safe)
      end.join(sep).html_safe
    else
      m.html_safe
    end
  end
  
  # gracefully show a range of dates
  def humanize_date_range(d1,d2,separator=" - ")
    d2,d1 = d1,d2 if d1 > d2
    return d1.to_time.to_formatted_s(:month_day_year) if (d1 == d2)
    return "#{d1.to_formatted_s(:month_day_year)}#{separator}#{d2.to_formatted_s(:month_day_year)}" if d1.year != d2.year
    # same year
    if d1.month == d2.month
      "#{d1.strftime('%b')} #{d1.mday}#{separator}#{d2.mday}, #{d1.year}"
    else
      "#{d1.strftime('%b %e')}#{separator}#{d2.strftime('%b %e')}, #{d1.year}"
    end
  end

  # if an option has some HTML text associated with it, sanitize the text;
  #  otherwise return the alternate text

  def sanitize_option_text(opt, tag, tag_options = {})
    s = Option.send(opt)
    content_tag(tag, sanitize(s), tag_options)
  end
  
  def link_to_if_option(opt, text, opts={})
    ((s = Option.send(opt)).blank? ?
      opts[:alt].to_s :
      content_tag(:span, link_to(text, s, opts), :id => opt, :class => opt))
  end

  def link_to_if_option_text(opt, path, html_opts={})
    if (s = Option.send(opt)).blank? then '' else
      content_tag(:span, link_to(s, path, html_opts), :id => opt, :class => opt)
    end
  end

  # Return a disabled 'default' menu selection for a dropdown
  def disabled_select_default(str)
    str = [str]
    options_for_select(str, :selected => str, :disabled => str).html_safe
  end

  # return a checkbox that "protects" another form element by hiding/showing it
  # when checked/unchecked, given initial state.  It's the caller's responsibility
  # to ensure the initial state matches the actual display state of the
  # guarded element.

  def checkbox_guard_for(elt_name, visible=false)
    check_box_tag("show_" << elt_name.to_s, '1', visible,
                  :onclick => %Q{$('##{elt_name}').slideToggle();})
  end

  # a checkbox that toggles the innerHTML of another guarded element.
  def check_box_toggle(name, checked, elt, ifchecked, ifnotchecked)
    check_box_tag name, 1, checked, :onchange => %Q{$('##{elt}').text($(this).is(':checked') ? '#{escape_javascript ifchecked}' : '#{escape_javascript ifnotchecked}')}
  end

  def purchase_link_popup(text,url,name=nil)
    msg = "This link points to a prepopulated Store page"
    msg << " for #{name}" if name
    msg << ":"
    link_to_function(text, "prompt('#{escape_javascript(msg)}', '#{escape_javascript(url)}')")
  end

  def link_to_subscription_purchase(vouchertype_id)
    url_for(:only_path => false, :controller => 'store', :action => 'subscribe',
            :vouchertype_id => vouchertype_id)
  end

end
