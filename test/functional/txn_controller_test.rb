require File.dirname(__FILE__) + '/../test_helper'
require 'txn_controller'

# Re-raise errors caught by the controller.
class TxnController; def rescue_action(e) raise e end; end

class TxnControllerTest < Test::Unit::TestCase
  def setup
    @controller = TxnController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
