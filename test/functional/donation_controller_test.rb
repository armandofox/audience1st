require File.dirname(__FILE__) + '/../test_helper'
require 'donation_controller'

# Re-raise errors caught by the controller.
class DonationController; def rescue_action(e) raise e end; end

class DonationControllerTest < Test::Unit::TestCase

  fixtures :customers,:donations
  
  def setup
    @controller = DonationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_sanitycheck
    simulate_logout
    # all of these require Boxofficemanager privilege
    %w[list new create mark_ltr_sent].each do |a|
      get a
      assert_redirected_to :controller => 'customers', :action => 'login'
    end
    simulate_login(customers(:staff_user))
    # still not enoguh privilege for list, mark_ltr_sent
    %w[list mark_ltr_sent].each do |a|
      get a
      assert_redirected_to :controller => 'customers', :action => 'login'
    end
  end

  def test_001_no_customer_specified
    simulate_login(customers(:staff_user)) # enough to record new
    get :new
    assert_flash /must select a customer/i
    assert_redirected_to :controller => 'customers',:action=>'list'
  end

end
