# Methods added to this helper will be available to all templates in the application.

module ApplicationHelper
  
  def to_js_array(arr)
      '[' + arr.map { |a| a.kind_of?(Fixnum) ? "#{a}" : "'#{a}'" }.join(',') + ']'
  end

  def strip_rcs_header(str)
    str.gsub( /\$\s*[^:]+:\s*([^$]+)\s*\$/, '\1' )
  end

  def admin_button(name,options={},html_opts={},*parms)
    #options.merge!(:method => :get) unless options.has_key?(:method)
    #button_to(name, options, html_opts.merge(:background=>:yellow))
    link_to(name, options,html_opts.merge(:class => 'adminButton'),parms)
  end

  def gen_button(name,options={},html_opts={},*parms)
    #options.merge!(:method => :get) unless options.has_key?(:method)
    #button_to(name, options, html_opts)
    link_to(name, options,html_opts.merge(:class => 'genButton'),parms)
  end

  def option_separator(name,value='')
    "<option disabled=\"disabled\" value=#{value}>#{name}</option>"
  end
                       
  def nav_tabs(*ary)
    ary.map do |a|
      a[0].insert(0,"<br/>") unless a[0].gsub!( /~/, "<br/>")
      if a.length > 3
        if a[3].nil?
          "<li class='disabled'>#{a[0]}</li>"
        else
          "<li id=\"t_#{a[1]}_#{a[2]}\">" <<
            link_to(a[0], {:controller => a[1].to_s,:action => a[2].to_s,
                      :id => a[3].id}.merge(a[4] || {})) <<
            "</li>"
        end
      else
        "<li id=\"t_#{a[1]}_#{a[2]}\">" <<
          link_to(a[0], {:controller => a[1].to_s,:action => a[2].to_s}) <<
          "</li>"
      end
    end.join("\n")
  end

  def button_bar(ary)
    ary.map do |a|
      options = {:controller => a[1].to_s, :action => a[2].to_s}
      admin_button a[0], options.merge(a[3])
    end.join("\n")
  end

  def pagination_bar(thispage, f, count, htmlopts={})
    s = ""
    curval = eval("@"+ f.to_s)  # value of the filter isntance variable
    s += link_to('<< Previous page', { :page => thispage.previous, f => curval}, htmlopts) if thispage.previous 
    s += sprintf(" %d - %d of %d ", thispage.first_item, thispage.last_item, count)
    s += link_to('Next page >>', { :page => thispage.next, f => curval}, htmlopts) if thispage.next
    s
  end
  
  def search_panel(controller, action_name='list', opts={}, html_opts={})
    form_tag_opts = {:method => :get}
    form_tag_opts.merge!(:target => '_blank') if opts[:newpage]
    s = ""
    s << start_form_tag({:controller => controller, :action => action_name},
                        form_tag_opts)
    s << (opts[:label] || 'Search/filter:')
    varname = Inflector.tableize(controller) + "_filter"
    s << text_field_tag(varname, eval("@#{varname}"))
    s << submit_tag((opts[:submit] || 'Search'), html_opts)
    s << end_form_tag
    s << " " + opts[:extra] if opts[:extra]
    s
  end

  def js_quote_nonnumeric(o)
    o.kind_of?(Fixnum) ? o: "'#{o}'"
  end

  def option_arrays(name, array_of_parents, key_method, vals_method,
                    text_method, args={})
    empty_val = (args[:empty_value] || -1).to_s
    empty_text = args[:empty_text] || "No #{name.pluralize} available"
    js = ''
    js << "var #{name}_value = new Array(#{array_of_parents.size});\n" 
    js << "var #{name}_text = new Array(#{array_of_parents.size});\n" 
    array_of_parents.map do |p|
      ndx = p.first.send(key_method)
      js << "#{name}_value['#{ndx}'] = "
      if p.last.empty?
        js << "[#{js_quote_nonnumeric(empty_val)}];\n" 
      else
        js << "[" << p.last.map { |c| js_quote_nonnumeric(c.send(vals_method)) }.join(',') << "];\n"
      end
      js << "#{name}_text['#{ndx}'] = "
      if p.last.empty?
        js << "[#{js_quote_nonnumeric(empty_val)}];\n" 
      else
        js << "[" << p.last.map { |c| js_quote_nonnumeric(c.send(text_method)) }.join(',') << "];\n"
      end
    end
    js
  end



  def array_of_arrays(array_name, array_of_parents, key_method, vals_method,
                      empty_val)
    js = ''
    js << "var #{array_name} = new Array(#{array_of_parents.size});\n" 
    array_of_parents.map do |p|
      js << "#{array_name}['#{p.first.send(key_method)}'] = "
      if p.last.empty?
        js << "[#{js_quote_nonnumeric(empty_val)}];\n"
      else
        js << "[" <<
          p.last.map { |c| js_quote_nonnumeric(c.send(vals_method)) }.join(',') << "];\n"
      end
    end
    js
  end

  # given an array each of whose elements is an array [parent, [child1,...childN]],
  # generate dynamic Javascript menus where the parent menu's onChange handler
  # constrains the child menu's choices.  id_method and text_method should be
  # methods the parent and child respond to that yield an id and name suitable for
  # options_ helpers.
  def dependent_js_selects(array_of_parents,
                           parent_name, parent_text_method,
                           child_name, child_text_method, args = {})
    parent_id_method = args[:parent_value_method] || 'id'
    child_id_method =  args[:child_value_method] || 'id'
    selected_parent = args[:selected_parent]
    selected_child = args[:selected_child]
    no_parent_avail_value = args[:no_parent_available_value] || -1
    no_parent_avail_text = args[:no_parent_available_text] || parent_name.pluralize
    no_child_avail_value = args[:no_child_available_value] || -1
    no_child_avail_text = args[:no_child_available_text] || child_name.pluralize
    # sanity check: does parent array have at least 1 element? does that
    # element consist of a parent item and an array of child items?
    unless array_of_parents.length >= 1 &&
        array_of_parents.first.kind_of?(Array)
      empty = "<select name='%s_select' id='%s_select'><option disabled='disabled'>No %s available</option></select>"
      parent_select=sprintf(empty,parent_name,parent_name,no_parent_avail_text)
      child_select=sprintf(empty, child_name, child_name, no_child_avail_text)
      return ['', parent_select, child_select]
    end
    # if no selected_parent indicated, or selected_parent not found,
    # just pick the first one
    par = nil
    if selected_parent
      par = array_of_parents.select { |p| p.first.send(parent_id_method) == selected_parent}
    end
    if par.nil? or par.empty?
      par = array_of_parents.first
    else
      par = par.first
    end
    chi = nil
    # If no selected_child indicated, pick the first child that would be
    # valid for the selected parent
    if selected_child
      chi = par.last.select {|c| c.send(child_id_method) == selected_child }
    end
    if chi.nil? or chi.empty?
      chi = par.last.first
    else
      chi = chi.first
    end
    unless selected_child
      selected_child = par.last.first.send(child_id_method) 
    end
    js = "<script language='javascript'> <!--\n" <<
      array_of_arrays("#{child_name}_value", array_of_parents, parent_id_method, child_id_method, no_child_avail_value) <<
      array_of_arrays("#{child_name}_text", array_of_parents, parent_id_method, child_text_method, no_child_avail_text)  <<
      "// -->\n</script>\n"
    #onchange_cmd = "v=this.options[this.selectedIndex].value; setOptions(\"#{child_name}_select\", #{child_name}_text[v], #{child_name}_value[v])"
    onchange_cmd = "setOptionsFrom('#{parent_name}','#{child_name}')"
    parent_select = "<select name=\"#{parent_name}_select\" id=\"#{parent_name}_select\" onChange=\"#{onchange_cmd}\" #{args[:parent_html_options]}>\n"
    parent_select << options_for_select(array_of_parents.map { |p| [p.first.send(parent_text_method), p.first.send(parent_id_method)] }, par.first.send(parent_id_method))
    parent_select << "\n</select>"
    child_select = "<select name='#{child_name}_select' id='#{child_name}_select' #{args[:child_html_options]}>"
    child_select << options_for_select(par.last.map { |c| [c.send(child_text_method), c.send(child_id_method)] },chi.send(child_id_method))
    child_select << '</select>'
    return [js, parent_select, child_select]
  end

  def dependent_js_arrays_from_collection(parent_array, child_name, *args)
    dependent_js_arrays(parent_array.map { |p| [p, p.send(child_name)] }, args)
  end

  def make_js_array(name,keys,values)
    s = "var #{name} = new Array();\n"
    collection.each do |elt|
      s <<  sprintf("#{name}[\"%s\"] = '%s';\n",
                    escape_javascript(elt.send(keymethod)),
                    escape_javascript(elt.send(valuemethod)))
    end
  end

  def stripeclass
    session[:row] = 1-(session[:row] || 0)
    return (session[:row].nonzero? ? 'oddRow' : 'evenRow')
  end

  def stripe
    # return bgcolor markup for alternating table stripes
    session[:row] = 1- (session[:row] || 0)
    return 'class=' + (session[:row].nonzero? ? 'oddRow' : 'evenRow')
  end

  def fmt_date(d)
    return (d ||= "").strftime('%b %e, %Y, %I:%M %p')
  end

  # create a set of dropdown selects to allow entry of an integral
  # dollar amount, given number of digits and default selection 
  def selects_for_dollar_amount(name, ndigits=1, default=0)
    #opts = (0..9).to_a.map { |i| "<option>#{i}</option>\n" }
    str = ''
    opts = (0..9).to_a.map { |i| [i, i.to_s] }
    default_val = sprintf("%0#{ndigits}d", default).split('')
    for i in 0..ndigits-1 do
      str << "<select id='#{name}[#{i}]' name='#{name}[#{i}]'>\n"
      str << options_for_select(opts, default_val[i])
      str << "</select>\n"
    end
    str
  end

  def select_menu_or_freeform(name, choices)
    lastidx = choices.length
    # should allow freeform entry as well as a menu of choices
    #select_tag = "<select name='#{name}_sel' onChange=\"t=document.getElementById('#{name}'); if this.selectedIndex==#{lastidx} { t.value=''; t.style.display='block'; } else { t.value=this.options[this.selectedIndex].value; t.style.display='none'; }\">"
    select_tag = "<select name='#{name}_sel' onChange=\"document.getElementById('#{name}').value=(this.selectedIndex==#{lastidx}? '':this.options[this.selectedIndex].value)\"\n"
    select_tag << options_for_select([""]+choices, "")
    select_tag << "\n</select>"
    select_tag << text_field_tag(name, '', {:size => 30, :maxlength => 30})
    select_tag
  end

  # generate two datetime_selects where the second is dynamically
  # dependent on the first (when first is changed, second clones the
  # change) 

  def parent_datetime_select(obj,meth,child,options)
    options = options.merge({:discard_type => true})
    pfx = "#{obj}[#{meth}(%di)]"
    thedate = options[:date] || Time.now
    ds = select_year(thedate, options.merge( {:prefix => sprintf(pfx,1) } ))
    ds << select_month(thedate, options.merge( {:prefix => sprintf(pfx,2) }))
    ds << select_day(thedate, options.merge( {:prefix => sprintf(pfx,3) }))
    ds << " &mdash; "
    ds << select_hour(thedate, options.merge( {:prefix => sprintf(pfx,4) } ))
    ds << select_minute(thedate, options.merge({:prefix => sprintf(pfx,5) }))
    i = 0
    ds.gsub!(/<select/) do |m|
      i=i+1
      "<select onChange='document.getElementById(\"#{child}_#{i}\").selectedIndex=this.selectedIndex'"
    end
  end

  def child_datetime_select(obj,meth,options)
    ds = datetime_select(obj, meth, options)
    #ds = select_datetime(options[:date], options.delete(:date))
    i = 0
    ds.gsub(/<select /) do |m|
      i =i +1 
      "<select id='#{meth}_#{i}' "
      #"<select id='#{meth}_#{i}' name=\"#{obj}[#{meth}_#{i}i]\">"
    end
  end

end
