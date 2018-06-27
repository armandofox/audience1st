module PopupHelpHelper

  def popup_help_for(item)
    unless (defined?(for_email)) || (m = t("popup_help.#{item}")).blank?
      render :partial => 'messages/popup_help', :object => m
    end
  end

end
