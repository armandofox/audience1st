module PopupHelpHelper

  def popup_help_for(item)
    unless (m = POPUP_HELP[item.to_sym]).blank?
      link_to_function "What's this?", "alert('#{escape_javascript(m)}')", {:class => 'popupHelpLink'}
    end
  end

end
