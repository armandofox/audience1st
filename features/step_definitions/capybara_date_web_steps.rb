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
    Time.parse(date_to_select)
end

def select_date_matching(date_to_select, options={})
  date = to_date(date_to_select)
  menu = find_field(options[:from] || raise(":from => 'field' is required"))
  choice = menu.all('option').detect do |opt|
    date == Time.parse(opt.text)
  end
  choice.select_option
end

def select_date(date_to_select, options ={})
  date = to_date(date_to_select)
  id_prefix = id_prefix_for(options)
  select_if id_prefix, :year, date.year
  select_if id_prefix, :month, date.strftime('%B')
  select_if id_prefix, :day, date.day
  select_if id_prefix, :hour, date.hour
  select_if id_prefix, :minute, date.min
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
  msg = "cannot select option, no select box with id, name, or label '#{options[:from]}' found"
  find(:xpath, "//label[contains(text(),'#{options[:from]}')]")['for']
end


When /^(?:|I )select "([^\"]*)" as the "([^\"]*)" (date|time)$/ do |date, date_label, _|
  select_date(date, :from => date_label)
end

