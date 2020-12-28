# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  include ActiveSupport::Inflector # so individual views don't need to reference explicitly

  def favicon_path
    if (u = Option.stylesheet_url).blank?  ||  u !~ /^http/i
      '/favicon.ico'
    else
      URI.join(u, 'favicon.ico').to_s
    end
  end

  def bootstrap_stylesheet_link_tag
    tag('link', {rel: "stylesheet", href: "https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css", integrity: "sha384-MCw98/SFnGE8fJT3GXwEOngsV7Zt27NXFoaoApmYm81iuXoPkFOJwJ8ERdknLPMO", crossorigin: "anonymous"})
  end

  def bootstrap_javascript_tag
    %q{<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js" integrity="sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM" crossorigin="anonymous"></script>}.html_safe
  end

  def venue_stylesheet_link_tag
    if (url = Option.stylesheet_url).blank?
      # use local
      url = '/assets/venue/default.css'
    end
    tag('link', {rel: "stylesheet", href: url, :media => 'all'})
  end

  def themed
    javascript_tag %Q{$(function() { $('#content').removeClass('a1-plain').addClass('themed'); });}
  end

  def link_icon
    content_tag(:span, '', :class => 'd-inline-block ui-icon ui-icon-link').html_safe
  end
  
  def display_customer_actions?
    ! @customer.try(:new_record?) &&
      ((controller.controller_name == 'customers' && action_name !~ /^index|list_duplicate/) ||
      (controller.controller_name == 'vouchers' && action_name == 'index')  ||
      (controller.controller_name == 'orders' && action_name == 'index'))
  end

  def display_order_in_progress?
    @gOrderInProgress &&
      %w(customers store sessions).include?(controller_name)  &&
      ! %w(place_order process_donation).include?(action_name)
  end

  # Render as HTML a multiline message passed as an array.
  # String elements are separated with +sep+.
  # Array elements become embedded lists.
  def render_multiline_message(msg,sep="<br/>\n")
    (msg.kind_of?(Array) ? msg.flatten.join(sep.html_safe) : msg.to_s).
      html_safe
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

  # Return a disabled 'default' menu selection for a dropdown
  def disabled_select_default(str)
    str = [str]
    options_for_select(str, :selected => str, :disabled => str).html_safe
  end

  # a checkbox that toggles the innerHTML of another guarded element.
  def check_box_toggle(name, checked, elt, ifchecked, ifnotchecked, opts={})
    check_box_tag name, 1, checked, opts.merge(:onchange => %Q{$('##{elt}').val($(this).is(':checked') ? '#{escape_javascript ifchecked}' : '#{escape_javascript ifnotchecked}' )})
  end

  def purchase_link_popup(text,url,name=nil)
    msg = "This link points to a prepopulated Store page"
    msg << " for #{name}" if name
    msg << ":"
    link_to(text, '#', :onclick => "prompt('#{escape_javascript(msg)}', '#{escape_javascript(url)}')", :class => 'a1-purchase-link')
  end

  def link_to_subscription_purchase(vouchertype_id)
    url_for(:only_path => false, :controller => 'store', :action => 'subscribe',
            :vouchertype_id => vouchertype_id)
  end

end
