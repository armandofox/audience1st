When /^I fill autocomplete field "(.*)" with "([^\"]*)"$/ do |field,value|
  fill_in(field, :with => value)
  page.should_not have_selector 'html.loading'
  page.execute_script(%{ $('##{field}').trigger('focus') })
  page.execute_script(%{ $('##{field}').trigger('keydown') })
end

Then /^I should (not )?see autocomplete choice "(.*)"/ do |no, text|
  wait_for_ajax
  selector = %Q{ul.ui-autocomplete li.ui-menu-item:contains('#{text}')}
  if no
    page.should_not have_selector(selector)
  else
    page.should have_selector(selector)
  end
end

When /^I select autocomplete choice "(.*)"$/ do |text|
  wait_for_ajax
  selector = %{ ul.ui-autocomplete li.ui-menu-item:contains('#{text}') }
  page.execute_script %Q{$("#{selector}").trigger('mouseenter').click() }
end

Then /^I should not see any autocomplete choices$/ do
  page.should_not have_selector('ui.ui-autocomplete li.ui-menu-item')
end
