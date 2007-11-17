require File.dirname(__FILE__) + '/../test_helper'
require 'customers_controller'

# Re-raise errors caught by the controller.
class CustomersController; def rescue_action(e) raise e end; end

class CustomersControllerTest < Test::Unit::TestCase
  fixtures :customers,:donations

  def setup
    @controller = CustomersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @emails = ActionMailer::Base.deliveries
    @emails.clear
    @params = {:customer => {
        'first_name' => 'Test', 'last_name' => 'Tester','street' => '123 Fake St',
        'city' => 'Springfield','state' => 'IL', 'zip' => '99999',
        'login' => 'tester@testing.com', 'password' => 'testing',
        'password_confirmation' => 'testing'
      }}
    simulate_logout
  end

  def change_admin_info(customer, look_for_admin_form, newcomment,newrole)
    c = customers(customer)
    get :edit, :id => c.id
    tags = [{:tag => 'div', :attributes => {:id => 'adminForm'}},
            {:tag => 'label', :attributes => {:for => 'customer_blacklist'}},
            {:tag => 'label', :attributes => {:for => 'customer_role'}},
            {:tag => 'label', :attributes => {:for => 'customer_comments'}}]
    if look_for_admin_form
      tags.each { |t| assert_tag t }
    else
      tags.each { |t| assert_no_tag t }
    end
    post :update, :id => c.id, :customer => {:comments => newcomment, :role => newrole}
  end

  def merge_prep
    params = {
      :v1 => Voucher.create!,
      :v2 => Voucher.create!,
      :d1 => donations(:cash_donation_general_10),
      :d2 => donations(:cash_donation_general_20),
      :cust0 => customers(:tom).id,
      :cust1 => customers(:tom2).id,
      :day_phone => 1,
      :eve_phone => 1
    }
    customers(:tom).vouchers << params[:v1]
    customers(:tom).donations << params[:d1]
    customers(:tom2).vouchers << params[:v2]
    customers(:tom2).donations << params[:d2]
    customers(:tom).save!
    customers(:tom2).save!
    params
  end

  def test_000_failed_login
    post :login, :customer => {:login => customers(:tom).login, :password => 'BAD'}
    assert_nil session[:cid]
    assert_flash( /mistyped your password/i)
    post :login, :customer => {:login => 'NOBODY', :password => 'BAD'}
    assert_flash(/can\'t find that email address/i)
    assert_nil session[:cid]
    post :login, :customer => {}
    assert_flash(/please provide both/i)
  end

  def test_001_double_login
    cust,admin = login_as(customers(:admin))
    assert_not_nil admin
    cust,admin = login_as(customers(:tom))
    assert_equal false, admin
    assert_redirected_to :action => 'welcome'
  end

  def test_0015_last_login
    c = customers(:tom)
    now = Time.now
    assert c.last_login < now
    cust,admin = login_as(customers(:tom))
    c.reload
    assert (c.last_login - now).abs < 3.seconds, "#{c.last_login} should be <= #{now}"
  end

  def test_002_must_be_logged_in
    [:index, :welcome, :change_password, :list, :show, :edit, :merge].each do |act|
      logout
      get act
      assert_redirected_to :action => 'login'
    end
    [:destroy, :create, :update, :merge].each do |act|
      logout
      post act
      assert_redirected_to :action => 'login'
    end
  end

  def test_003_non_admin_cant_view_cust_record
    simulate_login(customers(:tom))
    get :list
    assert_redirected_to :action => 'login'
  end

  def test_004_merge_records
    simulate_login(customers(:admin))
    params = merge_prep
    v1 = params.delete(:v1)
    v2 = params.delete(:v2)
    d1 = params.delete(:d1)
    d2 = params.delete(:d2)
    post :merge,params
    assert_redirected_to :action => 'welcome', :id => customers(:tom).id
    c0 = customers(:tom).reload
    assert_equal c0.day_phone, customers(:tom2).day_phone
    assert_equal c0.eve_phone, customers(:tom2).eve_phone
    assert_equal '123 Fake St',c0.street
    assert_not_nil c0.vouchers.find(v1.id)
    assert_not_nil c0.donations.find(d1.id)
    assert_not_nil c0.vouchers.find(v2.id)
    assert_not_nil c0.donations.find(d2.id)
    assert_raise(ActiveRecord::RecordNotFound) {
      Customer.find(customers(:tom2).id)
    }
  end

  def test_005_staff_create_customer_with_no_email_or_pass
    simulate_login(customers(:admin))
    post :create, {:customer => {:first_name => 'Test', :last_name => 'Tester'}}
    # shouldn't work - should re-render the 'new' template to fix errors
    assert_not_nil (c = Customer.find_by_last_name('Tester'))
    assert_redirected_to :action => 'welcome', :id => c.id
  end

  def test_0051_minimal_valid_customer
    simulate_login(customers(:admin))
    [:password,:password_confirmation,:login].each { |k| @params[:customer].delete(k) }
    post :create, @params
    # this should be legal
    assert_redirected_to :action => 'welcome'
    assert_flash /account was successfully created/i
    assert_not_nil Customer.find_by_last_name(@params[:customer]['last_name'])
  end

  def test_0052_user_must_provide_email
    ['password','password_confirmation','login'].each { |k| @params[:customer].delete(k) }
    post :create, @params        # should fail because not an admin
    assert_redirected_to :action => 'login'
    assert_flash /must sign in to view this page/i
    assert_nil Customer.find_by_last_name("Tester")
    post :user_create, @params   # should fail because no email
    assert_template 'new'
    assert_flash /please provide a valid email address/i
    assert_nil Customer.find_by_last_name("Tester")
  end

  def test_0053_user_must_provide_password
    @params[:customer]['password'] = @params[:customer]['password_confirmation'] = ''
    post :user_create, @params   # should fail because no p/w
    assert_template 'new'
    assert_tag :tag => 'li', :content => /password is too short/i
    assert_nil Customer.find_by_last_name("Tester")
  end

  def test_0054_successful_user_create
    post :user_create, @params   # should succeed
    assert_redirected_to :action => 'welcome'
    assert_not_nil Customer.find_by_last_name("Tester")
  end

  def test_0055_duplicate_login
    @params[:customer]['login'] = customers(:tom).login
    post :user_create, @params   # should fail because login not unique
    assert_template 'new'
    assert_tag :tag => 'li', :content => 'Login has already been taken'
    assert_nil Customer.find_by_last_name('Tester2')
  end

  def test_0070_forgot_password_bad_email
    parms = {:forgot_password => '1'}
    parms[:customer] = {:login => 'NotAnEmailAddress'}
    post :login, parms
    assert_redirected_to :action => :login
    assert_flash /does not appear to be a valid email/i
    assert_nil session[:cid]
  end

  def test_0071_forgot_password_not_in_db
    #unknown user
    parms = {:forgot_password => '1'}
    parms[:customer] = {:login => 'unknown@nowhere.com'}
    post :login, parms
    assert_redirected_to :action => :login
    assert_flash /not in our database/i
    assert_nil session[:cid]
  end

  def test_0072_forgot_password_empty_email
    # empty email
    parms = {:forgot_password => '1'}
    parms[:customer] = {:login => ''}
    post :login, parms
    assert_flash /please provide your login name/i
    assert_nil session[:cid]
  end

  def test_0073_forgot_password_invalid_email
    # invalid email
    parms = {:forgot_password => '1'}
    parms[:customer] = {:login => 'invalid_email'}
    post :login, parms
    assert_flash /does not appear to be a valid email address/i
    assert_nil session[:cid]
  end

  def test_080_forgot_password_send_email
    # valid login: should generate an email to user
    parms = {:forgot_password => '1'}
    parms[:customer] = {:login => customers(:tom).login }
    post :login, parms
    assert_redirected_to :action => :login
    assert_flash /email confirmation/i
    assert_equal 1, @emails.size
    msg = @emails.first
    assert_equal customers(:tom).login, msg.to[0]
    assert msg.body.match( /new password is:\s+([\d\w]+)/i  )
    newpass = Regexp.last_match(1)
    # try logging in with new password
    assert_nil session[:cid]
    parms.delete(:forgot_password)
    parms[:customer][:password] = newpass
    post :login, parms
    assert_redirected_to :action => 'welcome'
    assert_equal session[:cid], customers(:tom).id
  end

  def test_008_update_login
    # test to make sure an email is generated.
    #flunk
  end

  def test_009_admin_change_customer_role
    simulate_login(customers(:admin))
    newcomment = 'New comment'
    newrole = 'boxoffice'
    assert_not_nil customers(:admin).can_grant(newrole)
    change_admin_info(:tom,true, newcomment, newrole)
    c = customers(:tom)
    c.reload
    assert_equal newcomment, c.comments
    assert_equal Customer.role_value(newrole), c.role
  end

  def test_010_nonadmin_cant_change_role_or_comments
    simulate_login(c = customers(:tom))
    oldcomment = c.comments
    oldrole = c.role
    newcomment = "Can't change this"
    newrole = 'admin'
    change_admin_info(:tom,false, newcomment,  newrole)
    c.reload
    assert_equal oldcomment, c.comments
    assert_equal oldrole, c.role
  end

  def test_011_default_when_login
    simulate_login(customers(:tom))
    get :edit
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:customer)
  end

  def test_012_customer_cant_edit_contact
    tom = customers(:tom)
    simulate_login(tom)
    # post update event, should be turned back if not admin
    old_title = tom.title
    get :edit
    post( :update, {:id => tom.id,:customer => {:title => "#{old_title}_1"}} )
    assert_redirected_to :action => 'edit'
    assert_flash /some new attribute values were ignored/i
    tom.reload
    assert_equal tom.title, old_title
  end

  def test_013_name_capitalize
    # this test is here even though the name_capitalize method is actually
    # added to String (by application.rb).  I couldn't think of where else
    # to put this even though it is a unit test.
    tests = {
      "O'Leary" => "O'Leary",
      "OJ Simpson" => "OJ Simpson",
      "o.j. simpson" => "O. J. Simpson",
      "Tom w jones" => "Tom W. Jones",
      "Dell'angelo" => "Dell'angelo",
      "Dell'Angelo" => "Dell'Angelo",
      "Raymond O'Loan" => "Raymond O'Loan",
      "diMaggio" => "diMaggio",
      "McHugh" => "McHugh",
      "tom van der mark" => "Tom van der Mark",
      "Ludwig Von Beethoven" => "Ludwig von Beethoven"
    }
    tests.each_pair { |b,a| assert_equal a, b.name_capitalize }
  end

end
