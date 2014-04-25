# General attribute setting (model-direct) for setups
Given /^I set the (.*) of the (.*) with (.*) "(.*)" to (.*)$/ do |attr,model,finder_attr,finder_value,value|
  entity = get_model_instance(model,finder_attr,finder_value)
  entity.send(:update_attribute, attr.gsub(/ /,'_'), value)
end

# alias
Given /^the (.*) of the (.*) with (.*) "(.*)" is set to (.*)$/ do |attr,model,finder_attr,finder_value,value|
  steps %Q{Given I set the #{attr} of the #{model} with #{finder_attr} "#{finder_value}" to #{value}}
end
