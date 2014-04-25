When /^I fill in the "(.*)" fields as follows:$/ do |fieldset, table|
  table.hashes.each do |t|
    if t[:value] =~ /^select "(.*)"$/
      steps %Q{When I select "#{$1}" from "#{t[:field]}"}
    else
      steps %Q{When I fill in "#{t[:field]}" with "#{t[:value]}"}
    end
  end
end

