require File.dirname(__FILE__) + '/../test_helper'
require 'report_controller'

# Re-raise errors caught by the controller.
class ReportController; def rescue_action(e) raise e end; end

class ReportControllerTest < Test::Unit::TestCase

  fixtures :customers
  
  def setup
    @controller = ReportController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_sanity_001_no_unfulfilled_orders
    simulate_logout
    get :unfulfilled_orders
    assert_redirected_to :controller => 'customers', :action => 'login'
    simulate_login(customers(:admin))
    get :unfulfilled_orders
    assert_redirected_to :action => 'index'
  end

end
