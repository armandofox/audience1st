# The flexible code for resource testing came out of code from Ben Mabey
# http://www.benmabey.com/2008/02/04/rspec-plain-text-stories-webrat-chunky-bacon/

#
# Construct resources
#

#
# Build a resource as described, store it as an @instance variable. Ex:
#   "Given a user with login: 'mojojojo'"
# produces a Customer instance stored in @user with 'mojojojo' as its login
# attribute.
#
Given "a $resource instance with $attributes" do |resource, attributes|
  klass, instance, attributes = parse_resource_args resource, attributes
  instance = klass.new(attributes)
  instance.save!
  find_resource(resource, attributes).should_not be_nil
end

Given /^the following ([A-Z].*)s exist:/ do |thing, instances|
  klass = thing.gsub(/\s+/, '_').downcase.to_sym
  instances.hashes.each do |hash|
    FactoryGirl.create(klass, hash)
  end
end

#
# Stuff attributes into a preexisting @resource
#   "And the user has thac0: 3"
# takes the earlier-defined @user instance and sets its thac0 to '3'.
#
Given "the $resource has $attributes" do |resource, attributes|
  klass, instance, attributes = parse_resource_args resource, attributes
  attributes.each do |attr, val|
    instance.send("#{attr}=", val)
  end
  instance.save!
  find_resource(resource, attributes).should_not be_nil
end

#
# Destroy all for this resource
#
Given "no $resource with $attr: '$val' exists" do |resource, attr, val|
  klass, instance = parse_resource_args resource
  klass.destroy_all(attr.to_sym => val)
  instance = find_resource resource, attr.to_sym => val
  instance.should be_nil
end

#
# Then's for resources
#

# Resource like this DOES exist
Then /^a (\w+) with ([\w: \']+) should exist$/ do |resource, attributes|
  instance = find_resource resource, attributes
  instance.should_not be_nil
end
# Resource like this DOES NOT exist
Then /^no (\w+) with ([\w: \']+) should exist$/ do |resource, attributes|
  instance = find_resource resource, attributes
  instance.should be_nil
end

# Resource has attributes with given values
Then  "the $resource should have $attributes" do |resource, attributes|
  klass, instance, attributes = parse_resource_args resource, attributes
  attributes.each do |attr, val|
    instance.send(attr).to_s.should == val
  end
end

# Resource attributes should / should not be nil
Then  "the $resource's $attr should be nil" do |resource, attr|
  klass, instance = parse_resource_args resource
  instance.send(attr).should be_nil
end
Then  "the $resource's $attr should not be nil" do |resource, attr|
  klass, instance = parse_resource_args resource
  instance.send(attr).should_not be_nil
end

#
# Turn a resource name and a to_hash_from_story string like
#   "attr: 'value', attr2: 'value2', ... , and attrN: 'valueN'"
# into
#   * klass      -- the class matching that Resource
#   * instance   -- the possibly-preexisting local instance value @resource
#   * attributes -- a hash matching the given attribute-list string
#
def parse_resource_args resource, attributes=nil
  instance   = instantize resource
  klass      = resource.classify.constantize
  attributes = attributes.to_hash_from_story if attributes
  [klass, instance, attributes]
end

#
# Given a class name 'resource' and a hash of conditsion, find a model
#
def find_resource resource, conditions
  klass, instance = parse_resource_args resource
  conditions = conditions.to_hash_from_story unless (conditions.is_a? Hash)
  klass.find(:first, :conditions => conditions)
end
