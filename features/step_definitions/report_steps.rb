When /^I run the accounting report from "(.*)" to "(.*)"$/ do |from,to|
  When %Q{I visit the reports page}
  And %Q{I select "Earned Revenue" from "Report type"}
  And %Q{I select "#{Time.parse(from).to_formatted_s}" as the "From:" date}
  And %Q{I select "#{Time.parse(to).to_formatted_s}" as the "To:" date}
  And %Q{I press "Go"}
end
