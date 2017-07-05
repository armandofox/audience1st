#
# Build a resource as described, store it as an @instance variable. Ex:
#   "Given a user with login: 'mojojojo'"
# produces a Customer instance stored in @user with 'mojojojo' as its login
# attribute.
#

Given /^the following ([A-Z].*)s exist:/ do |thing, instances|
  klass = thing.gsub(/\s+/, '_').downcase.to_sym
  instances.hashes.each do |hash|
    FactoryGirl.create(klass, hash)
  end
end

# Resource has attributes with given values
Then  "the $resource should have $attributes" do |resource, attributes|
  klass, instance, attributes = parse_resource_args resource, attributes
  attributes.each do |attr, val|
    instance.send(attr).to_s.should == val
  end
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
