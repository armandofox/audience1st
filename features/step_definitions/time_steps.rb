When /^I note the time$/ do
	  @start = Time.now
end

When /^I wait (\d+) seconds$/ do |amount|
	  Time.stub(:now) { @start + amount.seconds }
end
