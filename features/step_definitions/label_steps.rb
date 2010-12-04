Given /the label "(.*)" exists/ do |name|
  Label.create!(:name => name)
end

Given /the label "(.*)" does not exist/ do |name|
  l = Label.find_by_name(name)
  l.destroy if l
end
