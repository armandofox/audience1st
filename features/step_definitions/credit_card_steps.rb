When /^I fill in the "(.*)" fields as follows:$/ do |fieldset, table|
  table.hashes.each do |t|
    if t[:value] =~ /^select "(.*)"$/
      When %Q{I select "#{$1}" from "#{t[:field]}"}
    else
      When %Q{I fill in "#{t[:field]}" with "#{t[:value]}"}
    end
  end
end

