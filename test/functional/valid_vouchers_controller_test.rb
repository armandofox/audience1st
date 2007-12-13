require File.dirname(__FILE__) + '/../test_helper'

# Re-raise errors caught by the controller.
class ValidVouchersController; def rescue_action(e) raise e end; end

class ValidVouchersControllerTest < Test::Unit::TestCase
  fixtures :valid_vouchers

  def setup
    @controller = ValidVouchersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_truth
    true
  end
end
