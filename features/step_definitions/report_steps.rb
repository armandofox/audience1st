When /^I run the accounting report from "(.*)" to "(.*)"$/ do |from,to|
  step %Q{I visit the reports page}
  step %Q{I select "Earned Revenue" from "Report type"}
  step %Q{I select "#{Time.parse(from).to_formatted_s}" as the "From:" date}
  step %Q{I select "#{Time.parse(to).to_formatted_s}" as the "To:" date}
  step %Q{I press "Go"}
end
