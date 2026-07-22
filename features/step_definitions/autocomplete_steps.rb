module AutocompleteScenarioHelper
  # CSS classes and other structure: https://github.com/tkirda/jQuery-Autocomplete
  def perform_autocomplete_search(value)
    @container = find(@container_selector)
    @id_result_field = find('#' + @container[:'data-autocomplete-id'], :visible => false)
    @container.send_keys(value)
    # wait for server response?
    expect(page).to have_css('.autocomplete-suggestions')
  end
  def suggestions_matching(text)
    all('.autocomplete-suggestion').filter do |elt|
      elt.text.include?(text)
    end
  end
end
World(AutocompleteScenarioHelper)

# One of the following must be called before any Then's are called, to setup search variables

When /^I search for customers matching "([^\"]*)"$/ do |value|
  @container_selector = '#customers_filter'
  perform_autocomplete_search(value)
end

When /^I select customer "(.*)" within "(.*)"$/ do |name,elt|
  @container_selector = "##{elt}"
  perform_autocomplete_search(name)
  steps %Q{When I select autocomplete choice "#{name}"}
end

Then /^the search results dropdown should (not )?include: (.*)/ do |no, text_list|
  suggestions = all('.autocomplete-suggestion').map(&:text)
  text_list.split(/\s*,\s*/).each do |text|
    if no
      expect(suggestions).not_to include(text)
    else
      expect(suggestions).to include(text)
    end
  end
end

When /^I list all matches$/ do
  # just submit the form
  @container.send_keys(:return)
end

When /^I select autocomplete choice "(.*)"$/ do |text|
  all_matches = suggestions_matching text
  expect(all_matches.length).to eq(1)
  all_matches[0].click
end

Then /^I should not see any autocomplete choices$/ do
  within('.autocomplete-suggestions') do
    expect(page).not_to(
      have_xpath(%Q{/div[contains(@class,"autocomplete-suggestion")]}))
  end
end
