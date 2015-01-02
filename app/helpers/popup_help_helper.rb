module PopupHelpHelper

  def popup_help_for(item)
    unless (defined?(for_email)) || (m = POPUP_HELP[item.to_sym]).blank?
      render :partial => 'messages/popup_help', :object => m
    end
  end

end
