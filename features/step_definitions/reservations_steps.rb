
Given /^customer "(.*) (.*)" has the following (subscriber )?reservations:/ do |first,last,sub,table|
  customer = find_or_create_customer(first,last)
  table.hashes.each do |res|
    vtype = find_or_create_or_default res[:vouchertype], (sub ? :vouchertype_included_in_bundle : :revenue_vouchertype)
    showdate = setup_show_and_showdate(res[:show], res[:showdate])
    vv = create(:valid_voucher, :vouchertype => vtype, :showdate => showdate)
    purchasemethod = purchasemethod_from_string res[:purchasemethod]
    order = create(:order, :processed_by => create(:boxoffice_manager), :customer => customer, :purchaser => customer, :purchasemethod => purchasemethod)
    order.add_tickets_without_capacity_checks(vv, res[:qty].to_i)
    order.finalize!
  end
end

When /I select the "(.*)" performance of "(.*)" from "(.*)"/ do |thedate, show,menu_selector|
  showdate_id = Show.includes(:showdates).find_by!(:name => show).
    showdates.find_by!(:thedate => Time.zone.parse(thedate)).
    id
  page.find_field(menu_selector).find("option[value='#{showdate_id}']").select_option
end
