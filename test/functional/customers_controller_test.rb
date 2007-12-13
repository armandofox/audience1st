require File.dirname(__FILE__) + '/../test_helper'
require 'application'
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

  def test_0000_failed_login
    post :login, :customer => {:login => customers(:tom).login, :password => 'BAD'}
    assert_nil session[:cid]
    assert_flash( /mistyped your password/i)
    post :login, :customer => {:login => 'NOBODY', :password => 'BAD'}
    assert_flash(/can\'t find that email address/i)
    assert_nil session[:cid]
    post :login, :customer => {}
    assert_flash(/please provide both/i)
  end

  def test_0010_double_login
    admin = customers(:admin)
    tom = customers(:tom)
    post :login, :customer => {:login => admin.login, :password=>'pass'}
    assert_not_nil session[:admin_id]
    assert_not_nil Customer.find(session[:admin_id]).is_staff
    assert_redirected_to :action=>'list'
    # now make sure new nonadmin login post clears out admin info
    post :login, :customer => {:login=>tom.login, :password=>'pass'}
    assert_nil session[:admin_id]
    assert_redirected_to :action => 'welcome'
  end

  def test_0011_last_login
    c = customers(:tom)
    now = Time.now
    assert c.last_login < now
    post :login, :customer=>{:login=>c.login,:password=>'pass'}
    c.reload
    assert (c.last_login - now).abs < 3.seconds, "#{c.last_login} should be <= #{now}"
  end

  def test_0019_must_be_logged_in_index
    simulate_logout
    get :index
    assert_redirected_to :action => 'welcome'
    follow_redirect
    assert_redirected_to :action => 'login'
  end

  def test_0020_must_be_logged_in
    [:welcome, :change_password, :list, :edit, :merge].each do |act|
      simulate_logout
      get act
      assert_redirected_to({:action => 'login'}, "(on 'get #{act}')")
    end
    [:destroy, :create, :merge].each do |act|
      simulate_logout
      post act
      assert_redirected_to({:action => 'login'}, "(on 'post #{act}')")
    end
  end

  def test_0021_logout
    post :logout
    assert_nil session[:cid]
    assert_nil session[:admin_id]
    assert_nil session[:store_customer]
    assert_nil session[:return_to]
    assert_nil session[:cart]
  end

#   def test_0022_effective_logged_in_id
#     simulate_logout
#     tom,admin = customers(:tom),customers(:admin)
#     post :login, :customer=>{:login=>tom.login,:password=>'pass'}
#     assert_redirected_to :action=>'welcome'
#     assert_equal tom.id, logged_in_id
#   end

#   def test_0023_effective_logged_in_id
#     simulate_logout
#     tom,admin = customers(:tom),customers(:admin)
#     post :login, :customer=>{:login=>admin.login,:password=>'pass'}
#     assert_redirected_to :action=>'list'
#     assert_equal admin.id, logged_in_id
#     # switch to another customer but verify that logged_in_id still points
#     # to admin
#     post :switch_to, :id => tom.id
#     assert_redirected_to :action=>'welcome'
#     assert_not_nil assigns(:customer)
#     assert_equal admin.id, logged_in_id
#   end
    
  def test_0030_non_admin_cant_view_cust_record
    simulate_login(customers(:tom))
    get :list
    assert_redirected_to :action => 'login'
  end

  def test_0040_merge_records
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

  def test_0050_staff_create_customer_with_no_email_or_pass
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
    assert_flash /must have at least boxoffice privilege/i
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
    assert_flash /please enter the email address/i
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

  def test_0080_update_login
    # test to make sure an email is generated.
    #flunk
  end

  def test_0088_switch_to
    simulate_login(customers(:admin))
    post :switch_to, :id => customers(:tom2)
    assert_redirected_to :action=>'welcome'
    assert_equal session[:cid], customers(:tom2).id
  end

  def test_0089_switch_to
    simulate_login(customers(:tom))
    post :switch_to, :id => customers(:tom2)
    assert_redirected_to :action => 'login'
    assert_equal session[:cid], customers(:tom).id
  end

  # helper method for the following 2 tests
  def customer_admin_form_tags
    [{:tag => 'div', :attributes => {:id => 'adminForm'}},
     {:tag => 'label', :attributes => {:for => 'customer_blacklist'}},
     {:tag => 'label', :attributes => {:for => 'customer_role'}},
     {:tag => 'label', :attributes => {:for => 'customer_comments'}}]
  end

  def test_0090_admin_change_customer_role
    simulate_login(customers(:admin))
    c = customers(:tom)
    post :switch_to, :id => c.id
    newcomment = 'New comment'
    newrole = 'boxoffice'
    assert_not_nil customers(:admin).can_grant(newrole)
    get :edit
    assert_not_nil assigns(:customer)
    customer_admin_form_tags.each { |t| assert_tag t }
    post :edit, :customer => {:comments=>newcomment,:role=>newrole}
    c.reload
    assert_equal newcomment, c.comments
    assert_equal Customer.role_value(newrole), c.role
  end

  def test_0100_nonadmin_cant_change_role_or_comments
    simulate_login(c = customers(:tom))
    oldcomment = c.comments
    oldrole = c.role
    newcomment = "Can't change this"
    newrole = 'admin'
    post :edit, :customer => {:comments=>newcomment,:role=>newrole}
    assert_redirected_to :action => 'welcome'
    c.reload
    assert_equal oldcomment, c.comments
    assert_equal oldrole, c.role
  end

  def test_0110_default_when_login
    simulate_login(customers(:tom))
    get :edit
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:customer)
  end

  def test_0120_customer_cant_edit_contact
    tom = customers(:tom)
    simulate_login(tom)
    # post update event, should be turned back if not admin
    old_title = tom.title
    post( :edit, {:customer => {:title => "#{old_title}_1"}} )
    assert_redirected_to :action => 'welcome'
    assert_flash /some new attribute values were ignored/i
    tom.reload
    assert_equal tom.title, old_title
  end

  def test_0130_customer_change_own_password
    simulate_logout
    simulate_login(customers(:tom))
    finish_password
  end

  def test_0131_admin_set_customer_password
    simulate_logout
    simulate_login(customers(:admin))
    post :switch_to, :id => customers(:tom)
    assert_equal customers(:admin).id, session[:admin_id]
    finish_password
  end

  def finish_password
    assert_nothing_raised { post :change_password, :customer=>{} }
    assert_flash /must set a non-empty password/
    assert_template 'change_password'
    post :change_password, :customer=>{:password => 'newpass'}
    assert_redirected_to :action=>'welcome'
    # make sure it worked
    simulate_logout
    post :login, :customer=>{:login=>customers(:tom).login,:password=>'newpass'}
    assert_redirected_to :action=>'welcome'
    assert_equal customers(:tom).id, session[:cid]
  end
  
  def test_0200_name_capitalize
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

  def test_0140_subscriber_welcome
    simulate_logout
    simulate_login(customers(:tom)) # tom is a subscriber
    get :welcome
    assert_redirected_to :action=>'welcome_subscriber'
  end

  def test_0150_nonsubscriber_welcome
    simulate_logout
    simulate_login(customers(:tom2)) # tom2 is not a subscriber
    get :welcome_subscriber
    assert_redirected_to :action=>'welcome'
  end

end
