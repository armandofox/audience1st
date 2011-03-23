When /^I run the accounting report from "(.*)" to "(.*)"$/ do |from,to|
  When %Q{I visit the reports page}
  And %Q{I select "Earned Revenue" from "Report type"}
  # ugh: need to override Webrat's concept of DATE_TIME_SUFFIXES so that these functions work with
  # date_select as well as select_date helpers
  old_suffixes = Webrat::Scope::DATE_TIME_SUFFIXES
  Webrat::Scope::DATE_TIME_SUFFIXES = {
    :year => 'year', :month => 'month', :day => 'day', :hour => 'hour', :minute => 'minute', :second => 'second'
  }
  And %Q{I select "#{Time.parse(from).to_formatted_s}" as the "From:" date and time}
  And %Q{I select "#{Time.parse(to).to_formatted_s}" as the "To:" date and time}
  Webrat::Scope::DATE_TIME_SUFFIXES = old_suffixes
  And %Q{I press "Go"}
end
