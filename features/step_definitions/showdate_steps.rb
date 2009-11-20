World(FixtureAccess)

Given /^a performance (?:of "([^\"]+)" )?(?:at|on) (.*)$/i do |name,time|
  time = Time.parse(time)
  name ||= "New Show"
  show = Show.create!(:name => name,
                      :opening_date => Date.today,
                      :closing_date => Date.today)
  @showdate = show.showdates.create!(:thedate => time, :max_sales => 100)
end
