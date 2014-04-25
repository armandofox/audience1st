When /^I run the accounting report from "(.*)" to "(.*)"$/ do |from,to|
  steps %Q{
  When I visit the reports page
  And I select "Earned Revenue" from "Report type"
  And I select "#{Time.parse(from).to_formatted_s}" as the "From:" date
  And I select "#{Time.parse(to).to_formatted_s}" as the "To:" date
  And I press "Go"
}
end
