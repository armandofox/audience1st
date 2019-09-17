Given /the seatmap "(.*)" exists/ do |name|
  create(:seatmap, :name => name)
end

When /I (press|follow) "(.*)" for the "(.*)" seatmap/ do |action,control,name|
  div_id = Seatmap.find_by!(:name => name).id
  within("#sm-#{div_id}") do
    steps %Q{When I #{action} "#{control}"}
  end
end
