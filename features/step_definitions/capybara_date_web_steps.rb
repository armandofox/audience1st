World(XPath)

require 'xpath'
DATE_TIME_SUFFIXES = {
  :year   => '1i',
  :month  => '2i',
  :day    => '3i',
  :hour   => '4i',
  :minute => '5i'
}

def to_date(date_to_select)
  date_to_select.kind_of?(Date) || date_to_select.kind_of?(Time) ?
  date_to_select :
    Time.zone.parse(date_to_select)
end

def select_date_matching(date_to_select, options={})
  date = to_date(date_to_select)
  menu = find_field(options[:from] || raise(":from => 'field' is required"))
  choice = menu.all('option').detect do |opt|
    date == Time.zone.parse(opt.text)
  end
  choice.select_option
end

def select_date_from_dropdowns(date_to_select, options ={})
  date = to_date(date_to_select)
  id_prefix = options[:from] =~ /^#(.*)/ ? $1 : id_prefix_for(options)
  select_if id_prefix, :year, date.year
  select_if id_prefix, :month, date.strftime('%B')
  select_if id_prefix, :day, date.day
  select_if id_prefix, :hour,  "%02d" % date.hour
  select_if id_prefix, :minute,"%02d" % date.min
end

def select_if(id_prefix, thing, val)
  id1 = [id_prefix, DATE_TIME_SUFFIXES[thing]].join('_')
  id2 = [id_prefix, thing].join('_')
  if page.has_xpath?("//select[@id='#{id1}']")
    select(val.to_s, :from => id1)
  elsif page.has_xpath?("//select[@id='#{id2}']")
    select(val.to_s, :from => id2)
  end
end


def id_prefix_for(options = {})
  name = options[:from]
  msg = "cannot select option, no select box with id, name, or label '#{name}' found"
  find(:xpath, "//label[contains(text(),'#{name}')]")['for']
end

def date_range_to_json(from,to)
  from = Time.zone.parse from
  to = Time.zone.parse to
  %Q[{"start":"#{from.strftime('%Y-%m-%d')}","end":"#{to.strftime('%Y-%m-%d')}"}]
end

When /^(?:|I )select "([^\"]*)" as the "([^\"]*)" (date|time)$/ do |date, date_label, _|
  select_date_from_dropdowns(date, :from => date_label)
end

When /^I select "(.*) to (.*)" as the "(.*)" date range$/ do |start,endr, selector|
  # relies on the formatting of the target field used as the datepicker; doesn't need JS
  fill_in selector, :with => date_range_to_json(start,endr)
end

Then /^"(.*) to (.*)" should be selected as the "(.*)" date range$/ do |from,to,selector|
  fmt = '%b %-d, %Y' # eg "Dec 3, 2016"
  dates = "#{Time.zone.parse(from).strftime(fmt)} - #{Time.zone.parse(to).strftime(fmt)}"
  page.find(:css,"##{selector}+button.comiseo-daterangepicker-triggerbutton").should have_content(dates)
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

