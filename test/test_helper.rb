ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'application'

class Test::Unit::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...

  # UGH! Why does this method have to be pasted in from application.rb?  
  # Why can't controller tests see the methods in application.rb??

  def login_as(u,p='pass')
    post :login, :customer => {:login => u.login, :password => p}
    assert_redirected_to :action => 'welcome', :controller => 'customers'
    assert_not_nil(session[:cid])
    cust = Customer.find(session[:cid])
    is_admin = cust.is_staff
    assert_equal cust.id, u.id
    return cust,is_admin
  end

  def login_as_admin
    login_as(customers(:admin))
  end

  def logout
    post :logout
    assert_nil session[:cid]
  end

  def simulate_login(u)
    if false|| (u == :admin)
      @request.session[:cid] = 1
    else
      @request.session[:cid] = u.id
    end
  end

  def simulate_logout()
    @request.session[:cid] = nil
  end

  def assert_flash(re)
    assert_match re, flash[:notice], flash[:notice]
  end

  def reserve(showdate,vouchertype,qty=1)
    qty.times { Voucher.create(:showdate_id => showdate.id,
                             :vouchertype_id => vouchertype.id,
                             :changeable => false,
                             :purchasemethod_id => 1,
                               :expiration_date => DateTime.now) }
  end

end
