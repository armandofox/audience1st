When /^I fill in the "(.*)" fields as follows:$/ do |fieldset, table|
  table.hashes.each do |t|
    case t[:value]
    when /^select date "(.*)"$/
      steps %Q{When I select "#{$1}" as the "#{t[:field]}" date}
    when /^select "(.*)"$/
      steps %Q{When I select "#{$1}" from "#{t[:field]}"}
    when /^(un)?checked$/
      steps %Q{When I #{$1}check "#{t[:field]}"}
    else
      steps %Q{When I fill in "#{t[:field]}" with "#{t[:value]}"}
    end
  end
end

