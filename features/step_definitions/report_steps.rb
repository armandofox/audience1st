When /^I fill in the special report "(.*)" with:$/ do |report_name, fields|
  visit path_to "the reports page"
  select report_name, :from => 'report_name'
  wait_for_ajax
  within '#report_body' do
    fields.hashes.each do |form_field|
      case form_field[:action]
      when /select/
        select form_field[:value], :from => form_field[:field_name]
      when /check/
        check form_field[:field_name]
      else
        raise "Unknown action #{form_field[:action]}"
      end
    end
  end
end

When /^I run the accounting report from "(.*)" to "(.*)"$/ do |from,to|
  steps %Q{
  When I visit the reports page
  And I select "Earned Revenue" from "Report type"
  And I select "#{from} to #{to}" as the "report_dates" date range
  And I press "Display report"
}
end
