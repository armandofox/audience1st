module PopupHelpHelper

  def popup_help_for(item)
    unless (m = APP_CONFIG[:popup_help][item.to_s]).blank?
      link_to_function "What's this?", "alert('#{escape_javascript(m)}')", {:class => 'popupHelpLink'}
    end
  end

end
