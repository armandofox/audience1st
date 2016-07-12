module AutocompleteField

  When /^I fill autocomplete field "(.*)" with ".*"$/ do |selector,value|
    @autocomplete_selector = selector
  end

  Then /^I should (not ?)see autocomplete choice "(.*)"/ do |no, value|
  end

  When /^I select autocomplete choice "(.*)"$/ do |value|
    
  end
  
end

World(AutocompleteField)
