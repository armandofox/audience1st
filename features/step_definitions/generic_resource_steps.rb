Given /^the following ([A-Z].*) exist:/ do |thing, instances|
  klass = thing.gsub(/\s+/, '_').classify.constantize
  instances.hashes.each do |hash|
    hash.each_pair do |k,v|
      if v =~ /^(\S+):(.*)$/
        hash["#{k}_id"] = k.classify.constantize.send("find_by_#{$1}!", $2)
        hash.delete(k)
      end
    end
    klass.send(:create!, hash)
  end
end


# Then /^the (.*) with (.*) "(.*)" should have an? (.*) of "(.*)"$/ do |model, finder_attribute, finder_value, attribute, value|
#   model.constantize.send("find_by_#{finder_attribute}", finder_value).
#     send(attribute).should == value
# end

# Given  /^the (.*) with (.*) "(.*)" has an? (.*) of "(.*)"$/ do |model, finder_attribute, finder_value, attribute, value|
#   model.constantize.send("find_by_#{finder_attribute}", finder_value).
#     send("#{attribute}=", value)
# end
