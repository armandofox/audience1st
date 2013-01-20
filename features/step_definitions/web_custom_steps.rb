require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

World(ModelAccess)

# Wrapper around 'I should see ... within ...' steps
Then /^I should see ([\"\/].*[\"\/]) within the "(.*)" (.*)$/ do |string,tag,id|
  Then %Q{I should see #{string} within "#{tag}[@id='#{id}']"}
end
Then /^I should not see ([\"\/].*[\"\/]) within the "(.*)" (.*)$/ do |string,tag,id|
  Then %Q{I should not see #{string} within "#{tag}[@id='#{id}']"}
end

# Check if menu option selected
Then /^"(.*)" should be selected in the "(.*)" menu$/ do |opt,menu|
  html = Nokogiri::HTML(page.body)
  menu_id = if !html.xpath("//select[@id='#{menu}']").empty? then menu else html.xpath("//label[contains(text(),'#{menu}')]").first['for'] end
  html.xpath("//select[@id='#{menu_id}']/option[contains(text(),'#{opt}')]").first['selected'].should_not be_blank
end

Then /^nothing should be selected in the "(.*)" menu$/ do |menu|
  html = Nokogiri::HTML(page.body)
  menu_id = if !html.xpath("//select[@id='#{menu}']").empty? then menu else html.xpath("//label[contains(text(),'#{menu}')]").first['for'] end
  within "##{menu_id}" do
    # there should exist a blank option
    page.should have_xpath("//option[contains(text(),'')]")
    # no nonblank option should be marked as 'selected'
    page.should have_no_xpath("//option[text() != '' and @selected='selected']")
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
    Then %Q{"#{date.year}" should be selected in the "#{menu_id}_#{year}" menu}
  end
  Then %Q{"#{date.strftime('%B')}" should be selected in the "#{menu_id}_#{month}" menu}
  Then %Q{"#{date.day}" should be selected in the "#{menu_id}_#{day}" menu}
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
  Then %Q{I should see "#{text}" within "#{tag_type}\##{selector_id}"}
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
  @html = Nokogiri::HTML(page.body)
  @rows = @html.xpath("//#{table}//tr").collect { |r| r.xpath('.//th|td') }
  col_regexps = row.split('|').map { |s| Regexp.new(s) }
  matched = @rows.any? do |table_row|
    match = true
    col_regexps.each_with_index do |regexp,index|
      match &&= table_row[index].content.match(regexp)
    end
    match
  end
  if flag =~ /not/
    matched.should be_false, "Expected #{table} NOT to contain a row matching <#{row}>"
  else
    matched.should be_true, "Expected #{table} to contain a row matching <#{row}>"
  end
end
    

Then /^I should see a table "(.*)" with rows? (.*)$/ do |table,all_rows|
  page.should have_css(table)
  all_rows.split(/, ?/).each do |row|
    Then "I should see a row #{row} within \"#{table}\""
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

  
