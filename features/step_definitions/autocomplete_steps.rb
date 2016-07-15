When /^I fill autocomplete field "(.*)" with "(.*)"$/ do |field,value|
  page.execute_script %Q{jQuery('#{field}').val('#{value}').keydown()}
  # fill_in field, :with => value
  # page.execute_script %Q{ jQuery('##{field}').trigger('focus') }
  # page.execute_script %Q{ jQuery('##{field}').trigger('keydown') }
end

Then /^I should (not )?see autocomplete choice "(.*)"/ do |no, value|
  selected_choice = %Q{ul.ui-autocomplete li.ui-menu-item a:contains("#{value}")}
  if no
    find('ul.ui-autocomplete').should_not have_content(value)
    #page.should_not have_selector(selected_choice)
  else
    find('ul.ui-autocomplete').should have_content(value)
    #page.should_not have_selector(selected_choice)
  end
end

When /^I select autocomplete choice "(.*)"$/ do |value|
  page.execute_script %Q{jQuery('.ui-menu-item:contains("#{value}")').find('a').trigger('mouseenter').click()}
  #selected_choice = %Q{ul.ui-autocomplete li.ui-menu-item a:contains("#{value}")}
  #page.execute_script %Q{ $('#{selected_choice}').trigger('mouseenter').click() }
end

