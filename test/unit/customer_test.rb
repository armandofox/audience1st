
require File.dirname(__FILE__) + '/../test_helper'

class CustomerTest < Test::Unit::TestCase
  fixtures :customers,:vouchertypes,:vouchers
  fixtures :txn_types, :purchasemethods
  self.use_transactional_fixtures = true
  
  def test_010_new_or_find
    c = customers(:tom)
    conds = ['last_name LIKE ? and first_name LIKE ?', c.last_name, c.first_name]
    assert_equal 1, Customer.count(:all,:conditions=>conds)
    c1 = Customer.new_or_find({:first_name => c.first_name, :last_name => c.last_name})
    # shold not have created a 2nd instance of this customer
    assert_equal 1, Customer.count(:all,:conditions=>conds)
    first2 = c.first_name+'xxx'
    assert_equal 0, Customer.count(:all,:conditions=>['last_name LIKE ? and first_name LIKE ?', c.last_name, first2])
    # this should create a new one
    c2 = Customer.new_or_find({:first_name => first2, :last_name => c.last_name})
    assert c2.kind_of?(Customer)
    assert_nothing_raised { Customer.find(c2.id) }
    assert_equal 1, Customer.count(:all,:conditions=>['last_name LIKE ? and first_name LIKE ?', c.last_name, first2])
    # in case of a duplicate, should also create a new one
    Customer.create!(:first_name => c.first_name, :last_name => c.last_name,
                     :login => 'INVALID')
    assert_equal 2, Customer.count(:all,:conditions=>conds)
    c3 = Customer.new_or_find({:first_name => c.first_name, :last_name => c.last_name})
    assert_equal 3, Customer.count(:all,:conditions=>conds)
  end

  def test_011_bad_save
    c = Customer.new(:first_name => "Bob", :last_name => "Builder")
    c.login = 'xx'              # too short
    assert_raise(ActiveRecord::RecordInvalid) { c.save! }
    c.login = 'tom@foolery.com' # duplicate
    assert_raise(ActiveRecord::RecordInvalid) { c.save! }
    c.login = 'legal@email.com'
    assert_nothing_raised { c.save! }
  end
      
  def test_012_create_with_no_email
    c = nil
    assert_nothing_raised { c=Customer.create!(:first_name => "No", :last_name => "Email") }
    assert_nothing_raised { c=Customer.find(c.id) }
    assert_nil c.has_valid_email_address?
  end

  def test_013_valid_email
    c = Customer.new
    ["", nil, "nodomain", "!abc", "123", "newbie@aol"].each do |e|
      c.email = e
      assert_nil c.has_valid_email_address?, e
    end
    ["joe@blow.info", "i@an.", "NEWBIE@AOL.COM"].each do |e|
      c.email = e
      assert_not_nil c.has_valid_email_address?, e
    end
  end

  def test_014_minimal_allowed_info
    c = Customer.new(:first_name => 'A', :last_name => 'B')
    assert_nothing_raised { c.save! }
  end
               
  def test_030_subscriber
    assert customers(:tom).is_subscriber?, customers(:tom).vouchers.inspect
    assert_nil customers(:tom2).is_subscriber?
  end

  def test_040_merge_with_null_login
    c0 = customers(:tom)
    c1 = customers(:tom2)
    c1.login = nil               # should be OK to merge
    assert_equal c0.login, "tom@foolery.com"
    result,msg = c0.merge_with(c1,{:login =>  1})
    assert_equal true,result,msg
    assert_raise(ActiveRecord::RecordNotFound) { Customer.find(c1.id) }
    assert_nil c0.reload.login
  end

  def test_042_real_customer
    assert customers(:tom).real_customer?
    assert ! (Customer.walkup_customer).real_customer?
  end
end
