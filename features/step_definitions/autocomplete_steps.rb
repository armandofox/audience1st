module AutocompleteScenarioHelper
  def perform_autocomplete_search(value)
    within(@container) do
      field = find(:css, '._autocomplete')['id']
      fill_in(field, :with => value)
      page.should_not have_selector 'html.loading'
      page.execute_script(%{ $('##{field}').trigger('focus') })
      page.execute_script(%{ $('##{field}').trigger('keydown') })
    end
  end
end
World(AutocompleteScenarioHelper)

When /^I search for customers matching "([^\"]*)"$/ do |value|
  @container = '#search_field'
  perform_autocomplete_search(value)
end

When /^I select customer "(.*)" within "(.*)"$/ do |name,elt|
  @container = "##{elt}"
  perform_autocomplete_search(name)
  steps %Q{When I select autocomplete choice "#{name}"}
end

Then /^the search results dropdown should (not )?include: (.*)/ do |no, text_list|
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
  xpath = %Q{//ul[contains(@class,"ui-autocomplete")]/li[contains(@class,"ui-menu-item") and contains(text(),'List all matching')]}
  element = within(@container) { find(:xpath,xpath) }
  element.click
end

When /^I select autocomplete choice "(.*)"$/ do |text|
  xpath = %Q{//ul[contains(@class,"ui-autocomplete")]/li[contains(@class,"ui-menu-item") and contains(text(),'#{text}') and not(contains(text(),'all matching'))]}
  element = within(@container) { find(:xpath,xpath) }
  element.click
end

Then /^I should not see any autocomplete choices$/ do
  xpath = %Q{//ul[contains(@class,"ui-autocomplete")]/li[contains(@class,"ui-menu-item")]}
  within(@container) { page.should_not have_xpath(xpath) }
end
