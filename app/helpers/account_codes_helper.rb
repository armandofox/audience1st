module AccountCodesHelper

  def account_code_with_popup_link(account_code)
    if account_code.name.blank?
      account_code.code.to_s
    else
      link_to_function(account_code.code,
        "alert('#{escape_javascript([account_code.name, account_code.description].join(': '))}')")
    end
  end

end
