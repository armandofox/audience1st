World()

Given /a show "(.*)" with "(.*)" tickets for \$(.*) on "(.*)"/ do |show,type,price,date|
  Given "there is a show named \"#{show}\""
  Given "a performance of \"#{show}\" on \"#{date}\""
  Given "100 #{type} vouchers costing $#{price} are available for this performance"
end

