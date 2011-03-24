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
  html = Nokogiri::HTML(response.body)
  menu_id = if !html.xpath("//select[@id='#{menu}']").empty? then menu else html.xpath("//label[contains(text(),'#{menu}')]").first['for'] end
  html.xpath("//select[@id='#{menu_id}']/option[contains(text(),'#{opt}')]").first['selected'].should_not be_blank
end

# Variant for dates
Then /^"(.*)" should be selected as the "(.*)" date$/ do |date,menu|
  date = Time.parse(date)
  html = Nokogiri::HTML(response.body)
  menu_id = html.xpath("//label[contains(text(),'#{menu}')]").first['for']
  Then %Q{"#{date.year}" should be selected in the "#{menu_id}_1i" menu}
  Then %Q{"#{Date::MONTHNAMES[date.month]}" should be selected in the "#{menu_id}_2i" menu}
  Then %Q{"#{date.day}" should be selected in the "#{menu_id}_3i" menu}
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
  @html = Nokogiri::HTML(response.body)
  elt1 = @html.xpath("//#{sel}//#{tag1}[contains(.,'#{val1}')]").first
  elt2 = @html.xpath("//#{sel}//#{tag2}[contains(.,'#{val2}')]").first
  sequence = (elt1 <=> elt2)
  if order =~ /before/
    assert sequence == -1
  else
    assert sequence == 1
  end
end

# For debugging help - dump actual HTML of a page to a file
Then /^\(?show me\)?$/ do
  save_and_open_page
  # name = response.request.request_uri.gsub(/[\/\#\?]/,'-')
  # File.open("/tmp/cucumber-#{name}.html", "w"){ |f| f.puts response.body }
  # system "open /tmp/cucumber-#{name}.html" 
end

# A dropdown menu of quantities associated with a particular voucher type.
# Capture the vouchertype label so we can refer to it later.

Then /^I should see a quantity menu for "([^\"]*)"$/ do |name|
  vtype = Vouchertype.find_by_name(name)
  response.should have_tag("select.itemQty[name='vouchertype[#{vtype.id}]']")
end

Then /^the "([^\"]*)" menu should contain "([^\"]*)"$/ do |menu,choice|
  response.should(have_tag("select[id=#{menu}]") || have_tag("select[name=#{menu}]")) do |m|
    m.should have_selector("option", :content => choice)
  end
end

Then /^I should see the "(.*)" message$/ do |m|
  response.should(have_selector("div##{m}") || have_selector("div.#{m}"))
end

# tabular data
Then /^I should see a row "(.*)" within "(.*)"$/ do |row, table|
  response.should have_selector(table)
  @html = Nokogiri::HTML(response.body)
  @rows = @html.xpath("//#{table}//tr").collect { |r| r.xpath('.//th|td') }
  col_regexps = row.split('|').map { |s| Regexp.new(s) }
  @rows.any? do |table_row|
    match = true
    col_regexps.each_with_index do |regexp,index|
      match &&= table_row[index].content.match(regexp)
    end
    match
  end.should be_true, "Expected #{table} to contain a row matching <#{row}>"
end
    

Then /^I should see a table "(.*)" with rows? (.*)$/ do |table,all_rows|
  response.should have_selector(table)
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

  
