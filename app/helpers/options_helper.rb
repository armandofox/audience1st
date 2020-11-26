module OptionsHelper

  def render_collection_of_options(frm, collection)
    content = ''
    collection.each do |attrib_with_decoration|
      attrib_with_decoration =~ /^([^!]+)!?(.*)$/
      content << (render :partial => 'option', :locals => {:attrib => $1, :decoration => $2, :f => frm}).html_safe
    end
    content.html_safe
  end

  # if an option has some HTML text associated with it, sanitize the text;
  #  otherwise return the alternate text

  def sanitize_option_text(opt, tag, tag_options = {})
    s = Option.send(opt)
    content_tag(tag, sanitize(s), tag_options)
  end
  
  def link_to_if_option(opt, text, opts={})
    (s = Option.send(opt)).blank? ?
      opts[:alt].to_s :
      link_to(text, s, opts)
  end

  def link_to_if_option_text(opt, path, html_opts={})
    if (s = Option.send(opt)).blank?
    then ''
    else link_to(s, path, html_opts)
    end
  end

end

