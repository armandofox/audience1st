Given /^the following ([A-Z].*)s exist:/ do |thing, instances|
  klass = thing.gsub(/\s+/, '_').downcase.to_sym
  instances.hashes.each do |hash|
    FactoryGirl.create(klass, hash)
  end
end


Then /^the (.*) whose (.*) is "(.*)" should have an? (.*) of "(.*)"$/ do |model, finder_attribute, finder_value, attribute, value|
  model.constantize.send("find_by_#{finder_attribute}!", finder_value).
    send(attribute).should == value
end

Then /^the (.*) whose (.*) is "(.*)" should have the following attributes:/ do |model, finder_attribute, finder_value, table|
  object = model.capitalize.constantize.send("find_by_#{finder_attribute}!", finder_value)
  table.raw.each do |attr_with_val|
    object.send(attr_with_val[0]).to_s.should == attr_with_val[1]
  end
end

# Given  /^the (.*) with (.*) "(.*)" has an? (.*) of "(.*)"$/ do |model, finder_attribute, finder_value, attribute, value|
#   model.constantize.send("find_by_#{finder_attribute}", finder_value).
#     send("#{attribute}=", value)
# end
