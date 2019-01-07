When /^I search for customers matching "([^\"]*)"$/ do |value|
  @container = "#search_field"        # save for future autocomplete steps
  within(@container) do
    field = find(:css, '._autocomplete')['id']
    fill_in(field, :with => value)
    page.should_not have_selector 'html.loading'
    page.execute_script(%{ $('##{field}').trigger('focus') })
    page.execute_script(%{ $('##{field}').trigger('keydown') })
  end
end

Then /^the search results dropdown should (not )?include: (.*)/ do |no, text_list|
  wait_for_ajax
  text = text_list.split(/\s*,\s*/)
  autocomplete_choices = %Q{//ul[contains(@class,"ui-autocomplete")]}
  within(@container) do
    expect(page).to have_xpath(autocomplete_choices)
    text_list.split(/\s*,\s*/).each do |text|
      item = autocomplete_choices +
        %Q{/li[contains(@class,"ui-menu-item") and contains(text(),'#{text}') and not(contains(text(),'all matching'))]}
      if no
        expect(page).not_to have_xpath(item)
      else
        expect(page).to have_xpath(item)
      end
    end
  end
end

When /^I select autocomplete choice to show all matches$/ do
  wait_for_ajax
  xpath = %Q{//ul[contains(@class,"ui-autocomplete")]/li[contains(@class,"ui-menu-item") and contains(text(),'List all matching')]}
  element = within(@container) { find(:xpath,xpath) }
  element.click
end

When /^I select autocomplete choice "(.*)"$/ do |text|
  wait_for_ajax
  xpath = %Q{//ul[contains(@class,"ui-autocomplete")]/li[contains(@class,"ui-menu-item") and contains(text(),'#{text}') and not(contains(text(),'all matching'))]}
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
