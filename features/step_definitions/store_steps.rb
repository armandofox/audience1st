Given /a show "(.*)" with "(.*)" tickets for \$(.*) on "(.*)"/ do |show,type,price,date|
  Given %Q{a performance of "#{show}" on "#{date}"}
  Given %Q{100 #{type} vouchers costing $#{price} are available for that performance}
end

