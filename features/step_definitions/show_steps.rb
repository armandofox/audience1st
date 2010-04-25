World()

When /^I specify a show "(.*)" playing from "(.*)" until "(.*)" with capacity "(.*)" to be listed starting "(.*)"/i do |name,opens,closes,cap,list|
  fill_in "Show Name", :with => name
  select_date(eval(opens), :from => "Opens")
  select_date(eval(closes), :from => "Closes")
  fill_in "Actual house capacity", :with => cap
  select_date(eval(list), :from => "List starting")
end
