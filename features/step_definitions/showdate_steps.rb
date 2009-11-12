World(FixtureAccess)

Given /^a performance (?:of "([^\"+])" )?at (\S+) ?(\S+)?$/i do |name,time,day|
  tm = Time.parse(time)
  tm.send(day) unless (day.blank? || day == "today")
  name ||= "New Show"
  show = Show.create!(:name => name,
                      :opening_date => Date.today,
                      :closing_date => Date.today)
  @showdate = show.showdates.create!(:thedate => tm, :max_sales => 100)
end
