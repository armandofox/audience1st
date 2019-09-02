module PopupHelpHelper

  def popup_help_for(item)
    unless (defined?(for_email)) || (m = t("popup_help.#{item}")).blank?
      render :partial => 'components/popup_help', :object => m
    end
  end
  def option_description_for(item)
    render :partial => 'components/popup_help', :object => t("option_descriptions.#{item}")
  end
end
