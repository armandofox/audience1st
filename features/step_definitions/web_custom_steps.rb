require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

World(ModelAccess)

# Field should have value
Then /^the "(.*)" field should be "(.*)"$/ do |field,val|
  page.should have_field(field, :with => val)
end
# Check for a JavaScript alert (when running with a JS-aware Capybara driver)

Then /^I should see an alert matching \/(.*)\/$/ do |regex|
  # Rails3 - the following should work with more recent Capybara
  # accept_alert().should match(Regexp.new regex)
end

# Check for N occurrences of something
Then /^(?:|I )should see \/([^\/]*?)\/ (within "(.*?)" )?(\d+) times$/ do |regexp, _, selector, count|
  regexp = Regexp.new(regexp, Regexp::MULTILINE)
  count = count.to_i
  if selector
    within(selector) { page.find(:xpath, '//*').text.split(regexp).length.should == 1+count }
  else
    page.find(:xpath, '//*').text.split(regexp).length.should == 1+count
  end
end

# Wrapper around 'I should see ... within ...' steps
Then /^I should see ([\"\/].*[\"\/]) within the "(.*)" (.*)$/ do |string,tag,id|
  steps %Q{Then I should see #{string} within "#{tag}[@id='#{id}']"}
end
Then /^I should not see ([\"\/].*[\"\/]) within the "(.*)" (.*)$/ do |string,tag,id|
  steps %Q{Then I should not see #{string} within "#{tag}[@id='#{id}']"}
end

# Check if menu option selected
Then /^"(.*)" should be selected in the "(.*)" menu$/ do |opt,menu|
  html = Nokogiri::HTML(page.body)
  menu_id = if !html.xpath("//select[@id='#{menu}']").empty? then menu else html.xpath("//label[contains(text(),'#{menu}')]").first['for'] end
  html.xpath("//select[@id='#{menu_id}']/option[contains(text(),'#{opt}')]").first['selected'].should_not be_blank, "Expected '#{opt}' to be selected in the '#{menu}' menu, but it was not"
end

Then /^nothing should be selected in the "(.*)" menu$/ do |menu|
  html = Nokogiri::HTML(page.body)
  menu_id = if !html.xpath("//select[@id='#{menu}']").empty? then menu else html.xpath("//label[contains(text(),'#{menu}')]").first['for'] end
  within "##{menu_id}" do
    # there should exist a blank option
    page.should have_xpath("//option[contains(text(),'')]"), "Menu doesn't have a blank option"
    # no nonblank option should be marked as 'selected'
    page.should have_no_xpath("//option[text() != '' and @selected='selected']"), "Expected menu's blank option to be selected, but it was not"
  end
end

# Variant for dates
Then /^"(.*)" should be selected as the "(.*)" date$/ do |date,menu|
  date = Date.parse(date)
  html = Nokogiri::HTML(page.body)
  menu_id = html.xpath("//label[contains(text(),'#{menu}')]").first['for']
  year, month, day =
    html.xpath("//select[@id='#{menu_id}_2i']").empty? ? %w[year month day] : %w[1i 2i 3i]
  if page.has_selector?("select##{menu_id}_#{year}")
    steps %Q{Then "#{date.year}" should be selected in the "#{menu_id}_#{year}" menu}
  end
  steps %Q{Then "#{date.strftime('%B')}" should be selected in the "#{menu_id}_#{month}" menu
           And  "#{date.day}" should be selected in the "#{menu_id}_#{day}" menu}
end

When /^I select "(.*) (.*)" as the "(.*)" month and day$/ do |month,day, menu|
  html = Nokogiri::HTML(page.body)
  menu_id = html.xpath("//label[contains(text(),'#{menu}')]").first['for']
  select(month, :from => "#{menu_id}_2i")
  select(day, :from => "#{menu_id}_3i")
end

# Select from menu using a regexp instead of exact string match
When /^I select \/([^\/]+)\/ from "(.*)"$/ do |rxp, field|
  select(Regexp.new(rxp), :from => field)
end

# 'I should see' within divs corresponding to named entities
Then /^(?:|I )should see "([^\"]*)" within the (.*) for(?: the) (.*) with (.*) "(.*)"$/ do |text,tag_type,entity_type,attribute,value|
  entity = get_model_instance(entity_type, attribute, value)
  selector_id = "#{entity_type}_#{entity.id}"
  steps %Q{Then I should see "#{text}" within "#{tag_type}\##{selector_id}"}
end

# 'should come before/should come after' for verifying orderings of things
Then /^(.*):"(.*)" should come (before|after) (.*):"(.*)" within "(.*)"$/ do |tag1,val1,order,tag2,val2,sel|
  html = Nokogiri::HTML(page.body)
  elt1 = html.xpath("//#{sel}//#{tag1}[contains(.,'#{val1}')]").first
  elt2 = html.xpath("//#{sel}//#{tag2}[contains(.,'#{val2}')]").first
  sequence = (elt1 <=> elt2)
  if order =~ /before/
    assert sequence == -1
  else
    assert sequence == 1
  end
end

# A dropdown menu of quantities associated with a particular voucher type.
# Capture the vouchertype label so we can refer to it later.

Then /^I should see a quantity menu for "([^\"]*)"$/ do |name|
  vtype = Vouchertype.find_by_name(name)
  page.should have_css("select.itemQty[name='vouchertype[#{vtype.id}]']")
end

Then /^the "([^\"]*)" menu should contain "([^\"]*)"$/ do |menu,choice|
  page.should(have_css("select[id=#{menu}]") || have_css("select[name=#{menu}]")) do |m|
    m.should have_css("option", :content => choice)
  end
end

Then /^I should see the "(.*)" message$/ do |m|
  page.should(have_css("div##{m}") || have_css("div.#{m}"))
end

# tabular data
Then /^I should (not )?see a row "(.*)" within "(.*)"$/ do |flag, row, table|
  page.should have_css(table)
  @rows = page.all(:xpath, "//#{table}//tr").collect { |r| r.all(:xpath, './/th|td') }
  col_regexps = row.split('|').map { |s| Regexp.new(s) }
  matched = @rows.any? do |table_row|
    match = true
    col_regexps.each_with_index do |regexp,index|
      match &&= (regexp.blank? || table_row[index].text.match(regexp))
    end
    match
  end
  if flag =~ /not/
    matched.should be_false, "Expected #{table} NOT to contain a row matching <#{row}>"
  else
    matched.should be_true, "Expected #{table} to contain a row matching <#{row}>"
  end
end

# match several rows
Then /^table "(.*)" should (not )?include:$/ do |result,negate,table|
  table_container = page.find(:css, result)

  # verify all column names specified are actually present in <th> elements
  result_headers = table_container.all(:xpath, "//tr//th").map(&:text)
  desired_headers = table.hashes.first.keys
  desired_headers.each { |column|  result_headers.should include(column) }

  # construct ColName => value hash for each result row, using ONLY the columns specified in desired results
  result_rows = table_container.all(:xpath, "//tbody/tr")
  result_hashes = Array.new(result_rows.length) { Hash.new }
  result_rows.each_with_index do |row,row_index|
    row.all(:xpath, "td").map(&:text).each_with_index do |col_value, col_position|
      col_name = result_headers[col_position]
      result_hashes[row_index][col_name] = col_value if desired_headers.include?(col_name)
    end
  end
  # verify all given results appear in table
  if negate =~ /not/
    table.hashes.all? { |hash| result_hashes.should_not include(hash) }
  else
    table.hashes.all? { |hash| result_hashes.should include(hash) }
  end
end

# File uploading
When /^I upload (.*) import list "(.*)"$/ do |type,file|
  case type
  when /customer/i
    path = "customer_list"
  when /brown/i
    path = "brownpapertickets"
  when /goldstar/i
    path = "email_goldstar"
  else
    raise "Unknown import type #{type}; try 'customer list', 'Brown Paper Tickets', or 'Goldstar'"
  end
  attach_file :import_uploaded_data, File.join(RAILS_ROOT, 'spec', 'import_test_files', path, file)
  click_button "Preview Import"
end

  
