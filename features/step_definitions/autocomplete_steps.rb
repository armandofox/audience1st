When /^I fill "(.*)" autocomplete field with "([^\"]*)"$/ do |container,value|
  @container = "##{container}"        # save for future autocomplete steps
  within(@container) do
    field = find(:css, '._autocomplete')['id']
    fill_in(field, :with => value)
    page.should_not have_selector 'html.loading'
    page.execute_script(%{ $('##{field}').trigger('focus') })
    page.execute_script(%{ $('##{field}').trigger('keydown') })
  end
end

Then /^I should (not )?see autocomplete choice "(.*)"/ do |no, text|
  wait_for_ajax
  autocomplete_choices = %Q{//ul[contains(@class,"ui-autocomplete")]}
  item = autocomplete_choices + %Q{/li[contains(@class,"ui-menu-item") and contains(text(),'#{text}')]}
  within(@container) do
    page.should have_xpath(autocomplete_choices)
    if no
      page.should_not have_xpath(item)
    else
      page.should have_xpath(item)
    end
  end
end

When /^I select autocomplete choice "(.*)"$/ do |text|
  wait_for_ajax
  xpath = %Q{//ul[contains(@class,"ui-autocomplete")]/li[contains(@class,"ui-menu-item") and contains(text(),'#{text}')]}
  element = within(@container) { find(:xpath,xpath) }
  element.click
end

Then /^I should not see any autocomplete choices$/ do
  xpath = %Q{//ul[contains(@class,"ui-autocomplete")]/li[contains(@class,"ui-menu-item")]}
  within(@container) { page.should_not have_xpath(xpath) }
end

When /^I select customer "(.*)" within "(.*)"$/ do |name,elt|
  steps %Q{
When I fill "#{elt}" autocomplete field with "#{name}"
And I select autocomplete choice "#{name}"
}
end
