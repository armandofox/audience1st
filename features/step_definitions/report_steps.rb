When /^I run the special report "(.*)" with:$/ do |report_name, fields|
  visit path_to "the reports page"
  select report_name, :from => 'report_name'
  within '#report_body' do
    fields.hashes.each do |form_field|
      case form_field[:action]
      when /select/
        select form_field[:value], :from => form_field[:field_name]
      else
        raise "Unknown action #{form_field[:action]}"
      end
    end
    
  end
end

When /^I run the accounting report from "(.*)" to "(.*)"$/ do |from,to|
  step %Q{I visit the reports page}
  step %Q{I select "Earned Revenue" from "Report type"}
  step %Q{I select "#{Time.parse(from).to_formatted_s}" as the "From:" date}
  step %Q{I select "#{Time.parse(to).to_formatted_s}" as the "To:" date}
  step %Q{I press "Go"}
end
