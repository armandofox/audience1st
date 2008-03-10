module ReportHelper

  def checkbox_for(attr)
    check_box_tag("use_#{attr.to_s}", "1", params["use_#{attr.to_s}".to_sym])
  end

  def select_have_or_have_not(positive="Have",negative="Have not")
    options_for_select([[positive,"1"],[negative,""]])
  end

  def vouchertypes_for_account_code(acc_code)
    "Account code #{acc_code}:\n" <<
      Vouchertype.find_all_by_account_code(acc_code).map { |vt| vt.name }.join("\n")
  end

end
