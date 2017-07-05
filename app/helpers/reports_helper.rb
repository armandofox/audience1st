module ReportsHelper

  def checkbox_for(attr)
    check_box_tag("use_#{attr.to_s}", "1", params["use_#{attr.to_s}".to_sym])
  end
    

  def vouchertypes_for_account_code(acc_code)
    "Account code #{acc_code} includes:\n" <<
      Vouchertype.where('account_code = ?', acc_code).
      map { |vt| vt.name }.join("\n")
  end

  def select_dates_with_defaults(div_name,select_name)
    custom = "Custom..."
    choices = ["Today", "This week", "This month", "Last month",
               "This year", "Last year", custom]
    select_tag(select_name, options_for_select(choices,choices.first),
               :onchange => "if (this.options[this.selectedIndex].value=='#{custom}') { Element.show('#{div_name}'); } else { Element.hide('#{div_name}'); }")
  end

  def account_code_with_links(kode)
    link_to(kode, '#', :onclick => "alert('" << escape_javascript(vouchertypes_for_account_code(kode.to_s)) << "')")
  end

  def link_to_stripe(text,auth)
    link_to text, "https://dashboard.stripe.com/payments/#{auth}", :target => '_blank'
  end

end
