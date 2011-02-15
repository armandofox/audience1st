Given /^a show "(.*)" with "(.*)" tickets for \$(.*) on "(.*)"$/ do |show,type,price,date|
  Given %Q{a show "#{show}" with 100 "#{type}" tickets for $#{price} on "#{date}"}
end

Given /^a show "(.*)" with (\d+) "(.*)" tickets for \$(.*) on "(.*)"$/ do |show,num,type,price,date|
  Given %Q{a performance of "#{show}" on "#{date}"}
  Given %Q{#{num} #{type} vouchers costing $#{price} are available for that performance}
end

