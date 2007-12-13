require File.dirname(__FILE__) + '/../test_helper'
require 'shows_controller'

# Re-raise errors caught by the controller.
class ShowsController; def rescue_action(e) raise e end; end

class ShowsControllerTest < Test::Unit::TestCase
  fixtures :shows,:customers

  def setup
    @controller = ShowsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # test destroying shows destroys all its showdates and valid_vouchers
  
  def test_destroy
    simulate_login(customers(:admin))
    show = shows(:upcoming_musical)
    vv = show.showdates.map { |v| v.valid_vouchers.map {|vv| vv.id }}.flatten
    get :destroy, :id => show.id
    assert_redirected_to :action => :list # only POST allowed for this
    assert_not_nil Show.find_by_id(show.id)
    post :destroy, :id => show.id
    assert_raise(ActiveRecord::RecordNotFound) { Show.find(show.id) }
    vv.each do |v|
      assert_raise(ActiveRecord::RecordNotFound) { ValidVoucher.find(v) }
    end
  end

end
