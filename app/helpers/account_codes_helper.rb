module AccountCodesHelper

  def account_code_with_popup_link(account_code)
    return '(none)' if account_code.blank?
    if account_code.name.blank?
      account_code.code.to_s
    else
      link_to "#{account_code.code} #{account_code.name}", '#', :onclick => "alert('#{escape_javascript(account_code.name_with_code)}')"
    end
  end

end
