Given /the seatmap "(.*)" exists/ do |name|
  create(:seatmap, :name => name)
end

When /I (press|follow) "(.*)" for the "(.*)" seatmap/ do |action,control,name|
  @seatmap = Seatmap.find_by!(:name => name)
  within("#sm-#{@seatmap.id}") do
    steps %Q{When I #{action} "#{control}"}
  end
end

When /I fill in the "(.*)" seatmap image URL as "(.*)" and name as "(.*)"/ do |sm,url,name|
  within("#sm-#{Seatmap.find_by!(:name => sm).id}") do
    fill_in "seatmap[image_url]", :with => url
    fill_in "seatmap[name]", :with => name
  end
end

Then /that seatmap should have image URL "(.*)" and name "(.*)"/ do |url,name|
  @seatmap.reload
  expect(@seatmap.name).to eq(name)
  expect(@seatmap.image_url).to eq(url)
end
