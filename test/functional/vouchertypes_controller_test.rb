require File.dirname(__FILE__) + '/../test_helper'
require 'vouchertypes_controller'

# Re-raise errors caught by the controller.
class VouchertypesController; def rescue_action(e) raise e end; end

class VouchertypesControllerTest < Test::Unit::TestCase
  fixtures :vouchertypes, :customers, :vouchers

  def setup
    @controller = VouchertypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    simulate_login(customers(:admin))
  end

  def test_001_sanity_check
    simulate_logout
    get_actions = %w[index list new]
    post_actions = %w[destroy create update]
    (get_actions + post_actions).each do |a|
      get a
      assert_redirected_to :controller => 'customers', :action => 'login'
    end
    simulate_login(customers(:admin))
    get_actions.each do |a|
      get a
      assert_response :success, "#{a} didn't succeed"
    end
    post_actions.each do |a|
      get a
      assert_response :redirect, "#{a} didn't redirect"
    end
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:vouchertypes)
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:vouchertype)
  end

  def test_create
    num_vouchertypes = Vouchertype.count

    post :create, :vouchertype => {
      :name => 'new vouchertype',
      :price => 10.00,
      :offer_public => 0
    }
    assert_redirected_to :action => 'list'
    assert_equal num_vouchertypes + 1, Vouchertype.count
  end

  def test_destroy
    assert_not_nil v=Vouchertype.find_first
    post :destroy, :id => v.id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Vouchertype.find(v.id)
    }
  end

  # TBD: test creation, editing, update of non-bundle
  # TBD: test creation ,editing, update of bundle
  # TBD: test changing from bundle to nonbundle and vice versa
end
