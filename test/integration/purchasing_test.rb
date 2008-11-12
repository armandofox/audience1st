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
    follow_redirect
    visit_page "/store/index"
  end

  def test_buy_regular_tickets
    show = shows(:upcoming_musical)
    showdt = showdates(:upcoming_musical_nomax)
    assert_menu :show, :containing => [show.id, show.name]
    assert_menu :showdate, :containing => [showdt.id, showdt.printable_date]
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


  private

  def visit_page(page,args={})
    unless (template = args[:template])
      raise "No page" unless (page.match( /[^\/]+$/ ))
      template = $1
    end
    if args[:method] == :post
      post page
      assert_response :success
      assert_template template
    end
  end
  
  def assert_menu(menu_id, args)
    contents = args[:containing]
    assert_tag(:tag => :select, :attributes => {:id => menu_id},
               :descendant => {:tag => 'option', :attributes => {:value => contents[0].to_s}, :content => contents[1].to_s})
  end

end
