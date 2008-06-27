require File.dirname(__FILE__) + '/../test_helper'
require 'custom_reports_controller'

# Re-raise errors caught by the controller.
class CustomReportsController; def rescue_action(e) raise e end; end

class CustomReportsControllerTest < Test::Unit::TestCase
  def setup
    @controller = CustomReportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
