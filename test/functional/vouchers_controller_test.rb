require File.dirname(__FILE__) + '/../test_helper'
require 'vouchers_controller'


# Re-raise errors caught by the controller.
class VouchersController; def rescue_action(e) raise e end; end

class VouchersControllerTest < Test::Unit::TestCase
  fixtures :customers
  fixtures :shows
  fixtures :showdates, :vouchertypes, :vouchers
  fixtures :valid_vouchers

  def setup
    @controller = VouchersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # see if customer who doesn't own a voucher can do any ops on it.
  # conversely, test that boxoffice or better CAN do it.
  def test_not_authorized_customer
    simulate_login(customers(:tom))
    tom3_voucher = vouchers(:tom3_type1)
    get :reserve, :id => tom3_voucher.id
    assert_response :redirect, flash[:notice]
    assert_redirected_to :controller => 'customers', :action => 'logout'
    simulate_login(customers(:tom3))
    get :reserve, :id => tom3_voucher.id
    assert_response :success, flash[:notice]
    assert_template 'reserve'
    simulate_login(customers(:boxoffice_user))
    session[:cid] = customers(:tom3).id
    get :reserve, :id => tom3_voucher.id
    assert_response :success
    assert_template 'reserve'
  end

  def test_addvoucher
  end

  def test_remove_voucher
  end

  def test_reserve
  end

  def test_confirm_reservation
  end

  def test_cancel_res
  end

  def test_cancel_prepaid
  end

end
