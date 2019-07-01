Then /the following "(.*)" tickets should have been imported for "(.*)":/ do |vtype,show,table|
  table.hashes.each do |h|
    steps %Q{Then customer "#{h['patron']}" should have #{h['qty']} "#{vtype}" tickets for "#{show}" on #{h['showdate']}}
  end
end
