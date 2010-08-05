module PopupHelpHelper

  def popup_help_for(item)
    unless (m = POPUP_HELP[item.to_sym]).blank?
      link_to_function "What's this?", "('#{escape_javascript(m)}')", {:class => 'popupHelpLink'}
      # content_tag :a, "What's this?", :title => m.gsub(/\s+/m, ' ').wrap, :class => 'popupHelpLink'
    end
  end

end
