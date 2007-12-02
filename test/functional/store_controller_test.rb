require File.dirname(__FILE__) + '/../test_helper'
require 'store_controller'


# Re-raise errors caught by the controller.
class StoreController; def rescue_action(e) raise e end; end

class StoreControllerTest < Test::Unit::TestCase
  fixtures :customers
  fixtures :shows
  fixtures :showdates, :vouchertypes, :vouchers
  fixtures :valid_vouchers

  def setup
    @controller = StoreController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.

  def test_0011_sanitycheck_nologin
    simulate_logout
    get :index
    assert_response :success
    assert_no_tag :tag => 'td', :content => "Logged in as"
  end

  def test_0012_sanitycheck_login
    simulate_login(customers(:tom))
    get :index
    assert_response :success
    assert_tag(:tag => 'td', :content => /Tom\s+Foolery/i,
               :attributes => {:id => 'welcome'},
               :parent => {:tag => 'tr'})
  end

  def test_0013_sanitycheck_postactions
    # make sure destructive actions require 'post'
    %w[checkout place_order do_walkup_sale add_tickets_to_cart
        add_subscriptions_to_cart add_donation_to_cart].each do |action|
      get action
      assert_response :redirect
    end
  end

  def test_002_swipe_parse
    simulate_login(customers(:admin))
    cards = [                   
             # test: lowercase output from some swipe readers
             {:swipe => '%b4022980000135555^fox/armando ^0912101113441100000000735000000?;4022980000135555=091210111344735?',
               :number => '4022980000135555', :type => 'visa',
               :first_name => 'ARMANDO', :last_name => 'FOX',
               :month => 12, :year => 2009},
             # visa card with tracks 1 and 2
             {:swipe => '%B4022333322221111^FOX/ARMANDO ^0912987987987900000000735000000?;4444333322221111=091298798798798?',
               :number => '4022333322221111', :type => 'visa',
               :first_name => 'ARMANDO', :last_name => 'FOX',
               :month => 12, :year => 2009},
             #  amex with tracks 1 and 2
             {:swipe => '%B371299988877776^FOX/ARMANDO               ^0810101041155170?;371299988877776=081010104115517000000?',
               :number => '371299988877776', :type => 'american_express',
               :first_name => 'ARMANDO', :last_name => 'FOX',
               :month => 10, :year => 2008},
             # check/debit card with tracks 1 and 2
             {:swipe => '%B4217666655554444^FOX/ARMANDO               ^10071011123100      00945000000?;4217666655554444=10071011123194500000?',
               :number => '4217666655554444', :type => 'visa',
               :first_name => 'ARMANDO', :last_name => 'FOX',
               :month => 7, :year => 2010}
            ]
    cards.each do |c|
      post :process_swipe, {:swipe_data => c[:swipe] }
      %w[first_name last_name number].each do |a|
        assert_tag :tag => 'input', :attributes => { :name => "credit_card[#{a}]", :value => c[a.to_sym]}
        # check month and year selects
      end
      [:month, :year, :type].each do |a|
        assert_tag :tag => 'option', :attributes => { :value => c[a].to_s, :selected => 'selected' }
      end

    end
  end

  def test_0100_which_shows_listed_nonadmin
    simulate_login(customers(:tom))
    get :index
    assert_response :success
    # make sure generic ticket type listed in menu
    assert_not_nil assigns(:cart)
    # make sure upcoming show is listed, past show is not
    assert_tag :tag => 'select', :attributes => {:name => 'show_id'}
    assert_tag :tag => 'option', :content => shows(:upcoming_musical).name, :attributes => {:value => shows(:upcoming_musical).id.to_s }
    assert_no_tag :tag => 'option', :content => shows(:past_musical).name
  end

  def test_0101_which_shows_listed_admin
    # for an admin, all shows should be visible
    simulate_logout
    simulate_login(customers(:admin))
    get :index
    assert_response :success
    assert_tag :tag => 'select', :attributes => {:name => 'show_id'}
    assert_tag  :tag => 'option', :content => shows(:past_musical).name
  end

  def test_021_subscriber_only_vouchers
    assert_not_nil customers(:tom).is_subscriber?
    simulate_login(customers(:tom))
    get :index
    # simulate selecting show
    xml_http_request(:get, :show_changed, :show_id => shows(:upcoming_musical).id)
    # showdates menu should appear
    %w[upcoming_musical_nomax upcoming_musical_hasmax_2].each do |sd|
      assert_tag :tag => 'option', :attributes => {:value => showdates(sd.to_sym).id.to_s}
    end
    # subscriber-only voucher should appear
    xml_http_request(:get, :showdate_changed,
                     :showdate_id => showdates(:upcoming_musical_hasmax_2).id)
    subscriber_tkt = {
      :tag => 'option',
      :parent => {:tag => "select", :attributes => {:name => 'vouchertype_id'}},
      :attributes => {:value => '5', :disabled => false},
      :content => /subscriber_only/i
    }
    assert_tag subscriber_tkt
    # now try same thing with nonsubscriber: subscriber voucher should be disabled
    assert_nil customers(:tom2).is_subscriber?
    simulate_login(customers(:tom2))
    get :index
    assert_response :success
    xml_http_request(:get, :show_changed, :show_id => shows(:upcoming_musical).id)
    xml_http_request(:get, :showdate_changed,
                     :showdate_id => showdates(:upcoming_musical_hasmax_2).id)
    # CHANGED: subscriber-only voucher used to appear but disabled in menu.
    # but neither IE6 nor Safari 2 implement 'disabled' properly, so  now
    # we just don't display the item.  Hence the test case changes too.
    #subscriber_tkt[:attributes] = {:disabled => true}
    #assert_tag subscriber_tkt
    assert_no_tag subscriber_tkt
  end

  def test_022_promo_code
    promo_tkt = {
      :tag => 'option',
      :parent => {:tag => "select", :attributes => {:name => 'vouchertype_id'}},
      :attributes => {:value => '6'}
    }
    simulate_login(customers(:tom))
    cid = customers(:tom).id
    get :index;  assert_response :success
    # select show date that has promo vouchers
    select_show_and_showdate(:upcoming_musical, :upcoming_musical_hasmax_2)
    # assert that promo price doesn't appear initially
    assert_no_tag promo_tkt
    # try enter wrong code
    get :index; assert_response :success
    post :enter_promo_code, :promo_code => "WRONGCODE", :id => cid
    assert_redirected_to :action => 'index';   follow_redirect
    #xml_http_request(:post, :enter_promo_code, :promo_code => "WRONGCODE")
    select_show_and_showdate(:upcoming_musical, :upcoming_musical_hasmax_2)
    assert_no_tag promo_tkt
    # enter the promo code - must reload index page first
    #get :index;  assert_response :success
    post(:enter_promo_code, :id => cid,
         :promo_code => valid_vouchers(:upcoming_musical_promo_1).password.downcase)
    assert_redirected_to :action => 'index';   follow_redirect
    #xml_http_request(:post, :enter_promo_code,
    # now select show and showdate again
    select_show_and_showdate(:upcoming_musical, :upcoming_musical_hasmax_2)
    assert_tag promo_tkt
    # also try with a valid_voucher that has multiple promo codes
    valid_vouchers(:upcoming_musical_promo_2).password.downcase.split(',').each do |c|
      get :index
      assert_response :success
      session[:promo_code] = nil
      select_show_and_showdate(:upcoming_musical, :upcoming_musical_nomax)
      assert_no_tag promo_tkt
      post(:enter_promo_code, :promo_code => c, :id => cid)
      assert_redirected_to :action => 'index'; follow_redirect
      #xml_http_request(:post, :enter_promo_code, :promo_code => c)
      select_show_and_showdate(:upcoming_musical, :upcoming_musical_nomax)
      assert_tag promo_tkt
    end
    # when add to cart, make sure promo code is preserved since it has to be
    # recorded with voucher
    promo_vchr = {
      :tag => 'td',
      :parent => {:tag => 'tr'},
      :attributes => {:id => 'vouchertype_name'},
      :content => Regexp.new(valid_vouchers(:upcoming_musical_promo_1).password, Regexp::IGNORECASE)
    }
    # try to add too many tickets (limited to 1)
    post(:add_tickets_to_cart, :id => customers(:tom).id, :qty => 2,
         :vouchertype_id => 6,
         :showdate_id => showdates(:upcoming_musical_nomax).id)
    assert_redirected_to :action => 'index'
    assert_match /only 1 of these tickets remaining/i, flash[:ticket_error]
    assert_no_tag promo_vchr
    # see if ticket made it to cart
    # try to add just 1 ticket - should succeed
    post(:add_tickets_to_cart, :id => customers(:tom).id, :qty => 1,
         :vouchertype_id => 6,
         :showdate_id => showdates(:upcoming_musical_nomax).id)
    assert_redirected_to :action => 'index'
    follow_redirect
    assert_tag promo_vchr
  end

  def test_050_walkup_1
    simulate_login(customers(:admin))
    get :walkup
    assert_response :success
    # select a show and showdate that are not the default.  Verify that after a
    # failed txn, the same show and showdate are still selected.
  end

  def select_show_and_showdate(s,sd)
    xml_http_request(:get, :show_changed, :show_id => shows(s).id)
    xml_http_request(:get, :showdate_changed, :showdate_id => showdates(sd).id)
  end

end
