World(FixtureAccess)

When /^I visit the Store page$/i do
  visit '/store'
end

Then /^I should see the (.*) message$/ do |m|
  response.should have_selector("div.storeBanner#{m}")
end
