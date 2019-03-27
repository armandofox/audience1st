When /^I note the time$/ do
	  @start = Time.now
end

When /^I wait (\d+) seconds$/ do
	  Time.stub(:now) { @start + 5.seconds }
end
