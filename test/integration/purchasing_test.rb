require "#{File.dirname(__FILE__)}/../test_helper"

module ActionController
  module TestProcess
    def html_document
      HTML::Document.new(@response.body)
    end
  end
end

class PurchasingTest < ActionController::IntegrationTest
  fixtures :customers, :shows, :showdates, :vouchertypes, :vouchers

  def setup
    post "/customers/logout"
  end

  def visit_store_without_login
    post "/customers/logout"
    get "/store/index"
    assert_response :success
    assert_template "index"
    assert_no_tag :tag => 'td', :content => /logged in as/i
    assert_no_tag(:tag => 'input', :attributes => {:name => 'id', :id => 'id',
                   :type => 'hidden', :value => /[0-9-]+/})
  end

  def select_show(show)
    assert_tag :tag => 'select', :attributes => {:name => 'show_id'}
    assert_tag :tag => 'option', :content => Regexp.new(show.name), :attributes => {:value => show.id.to_i}
    xml_http_request("/store/show_changed", :show_id => show.id, :id => @custid)
  end

  def select_showdate(showdate)
    assert_tag :tag => 'select', :attributes => {:name => 'showdate_id'}
    assert_tag :tag => 'option', :attributes => {:value => showdate.id.to_s}
    xml_http_request("/store/showdate_changed", :showdate_id => showdate.id, :id => @custid)
    assert_tag :tag => 'select', :attributes => {:name => 'vouchertype_id'}
  end

  def assert_cart_empty
    assert_tag :tag => 'p', :content => /shopping cart is empty/i
  end

  def assert_cart_contains_ticket(qty, sd, vtype)
    cart_tbl = {:tag => 'table', :attributes => {:class => 'cart'}}
    showname = {:tag => 'td', :content => Regexp.new(sd.show.name, :ignore_case)}
    showdt = {:tag => 'td', :content => sd.thedate.strftime('%b %e, %Y, %I:%M %p')}
    vt = {:tag => 'td', :content => Regexp.new(vtype.name) }
    tr = {:tag => 'tr'}
    assert_tag cart_tbl.merge(:descendant => tr)
    assert_tag showname.merge(:ancestor => cart_tbl)
    assert_tag showdt.merge(:ancestor => cart_tbl)
    assert_tag vt.merge(:ancestor => cart_tbl)
  end
  
  def try_add_tkts_to_cart(qty,type)
    post_via_redirect "/store/add_tickets_to_cart", :qty => qty.to_s, :vouchertype_id => type.to_s
    assert_template "index"
    assert_tag :tag => 'h1', :content => /shopping cart/i
  end
    
  # Replace this with your real tests.
  def XX_test_buy_regular_ticket
    # go to the store page
    visit_store_without_login
    assert_cart_empty
    my_show = shows(:upcoming_musical)
    my_showdate = showdates(:upcoming_musical_hasmax_2)
    my_tkt = vouchertypes(:single_generic_1_offerpublic)
    select_show(my_show)
    select_showdate(my_showdate)
    try_add_tkts_to_cart(1, my_tkt)
    assert_cart_contains_ticket(1, my_showdate, my_tkt)
  end
end
