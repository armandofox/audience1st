require File.dirname(__FILE__) + '/../test_helper'
require 'showdates_controller'

# Re-raise errors caught by the controller.
class ShowdatesController; def rescue_action(e) raise e end; end

class ShowdatesControllerTest < Test::Unit::TestCase
  fixtures :showdates

  def setup
    @controller = ShowdatesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_truth
    true
  end
end
