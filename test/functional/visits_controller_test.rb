require File.dirname(__FILE__) + '/../test_helper'
require 'visits_controller'

# Re-raise errors caught by the controller.
class VisitsController; def rescue_action(e) raise e end; end

class VisitsControllerTest < Test::Unit::TestCase
  def setup
    @controller = VisitsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @admin = customers(:admin)
    @tom = customers(:tom)
    @tom2 = customers(:tom2)
  end

  fixtures :customers, :visits
  
  def test_001_not_logged_in
    simulate_logout
    get :list
    assert_redirected_to :controller => 'customers', :action => 'login'
  end

  def test_002_not_staff
    simulate_login(@tom)
    get :list
    assert_redirected_to :controller => 'customers', :action => 'login'
    assert_flash /must have at least staff privilege/i
  end

  def test_003_sanitycheck
    simulate_login(@admin)
    get :list
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:visit)
    assert_not_nil assigns(:logged_in_id)
  end

  def test_004_successful_create_visit
    assert_equal 0, @tom.visits.length
    simulate_login(@admin)
    get :list, :id => @tom.id
    assert_response :success
    assert_no_tag :tag => 'div', :attributes => {:id => 'previousVisits'}
    assert_not_nil assigns(:logged_in_id)
    post :create, :visit => generic_visit_by_for(@admin,@tom)
    assert_flash /visit information saved/i
    assert_redirected_to :action => 'list', :id => @tom.id
    @tom.reload
    assert_equal 1, @tom.visits.length
  end

  def test_005_list_existing_visits
    simulate_login(@admin)
    assert_equal 3, @tom2.visits.length
    get :list, :id => @tom2.id
    assert_response :success
    assert_tag :tag => 'div', :attributes => {:id => 'previousVisits'}
    (1..3).each { |i| assert_tag :tag => 'div', :attributes => {:id => "visit_#{@tom2.visits[i-1].id}"} }
  end
  
  def generic_visit_by_for(by,cust,notes="Notes")
    return({
             :thedate => Date.today,
             :visited_by_id => by.id,
             :customer_id => cust.id,
             :contact_method => 'Phone',
             :location => 'The theater',
             :purpose => 'Other',
             :result => 'Further cultivation',
             :additional_notes => notes,
             :followup_date => Date.today + 1.week,
             :followup_action => 'Call back',
             :next_ask_target => 100,
             :followup_assigned_to_id => by.id
           })
  end
  
end
