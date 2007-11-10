module StoreHelper

  # shows[show_id] => name
  # vouchertype[id] => desc
  # showdates[showdate_id] => array of  vouchertype_id => descr
      

  def select_with_onchange(name,choices,url_args,selected_tag,selected_val)
    url = url_for(url_args)
    str = "<select name='#{name}' onChange=\"window.location.href='#{url}?#{selected_tag}='+this.options[this.selectedIndex].value\">"
    str << options_for_select(choices,selected_val.to_i)
    str << "\n</select>\n"
    str
  end

end
