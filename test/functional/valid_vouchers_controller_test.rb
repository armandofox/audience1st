require File.dirname(__FILE__) + '/../test_helper'
require 'valid_vouchers_controller'

# Re-raise errors caught by the controller.
class ValidVouchersController; def rescue_action(e) raise e end; end

class ValidVouchersControllerTest < Test::Unit::TestCase
  fixtures :valid_vouchers, :showdates, :shows, :vouchertypes, :customers

  def setup
    @controller = ValidVouchersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    simulate_login(customers(:admin))
  end

  def to_date_selects(key,t)
    {
      "#{key}(1i)"=> t.year.to_s,  
      "#{key}(2i)"=> t.month.to_s, 
      "#{key}(3i)"=> t.day.to_s,   
      "#{key}(4i)"=> t.hour.to_s,  
      "#{key}(5i)"=> t.min.to_s,
    }
  end

  def test_0100_end_date_for_one_show
    vv = valid_vouchers(:upcoming_musical_hasmax_2_single_generic_1_offerpublic)
    dt = vv.showdate.thedate - 1.hour
    tnow = Time.now.change(:sec => 0)
    h = 4                       # hours before showtime
    params = {
      :valid_voucher => to_date_selects("end_sales",dt).merge(to_date_selects("start_sales",tnow)),
      :id => vv.id.to_s,
      :end_is_relative => "0",
      :hours_before => h.to_s,
    }
    post :update, params ;  assert_flash /update successful/i
    assert_redirected_to :controller => 'shows', :action => 'edit', :id => vv.showdate.show_id
    vv.reload
    assert_equal tnow, vv.start_sales
    assert_equal dt, vv.end_sales
    # now try "N hours before" setting
    params[:end_is_relative] = "1"
    post :update, params ; assert_flash /update successful/i
    assert_redirected_to :controller => 'shows', :action => 'edit', :id => vv.showdate.show_id
    vv.reload
    assert_equal vv.end_sales, vv.showdate.thedate - h.hours
  end

  def test_0101_end_date_for_one_show_create
    sd = showdates(:upcoming_musical_hasmax_2) # this "show" has 1 other perf
    fixed_end = (Time.now + 1.day).change(:sec => 0)
    h = 2.5
    vtype = vouchertypes(:not_used_by_any_fixture)
    params = {
      :end_is_relative => "1",
      :hours_before => h.to_s,
      :addtojustone => "1",
      :valid_voucher => {
        :password => "I AM UNIQUE",
        :vouchertype_id => vtype.id,
        :showdate_id => sd.id.to_s,
        :max_sales_for_type => "0"
      }.merge(to_date_selects("end_sales",fixed_end)).merge(to_date_selects("start_sales",Time.now.change(:sec=>0)))
    }
    post :create, params
    assert_flash /added to date/i
    assert_not_nil( vv= ValidVoucher.find_by_password("I AM UNIQUE"))
    assert_equal sd.thedate, vv.showdate.thedate
    assert_equal sd.thedate - h.hours, vv.end_sales
  end

  def test_0102_end_date_for_many_shows
    sd = showdates(:upcoming_musical_hasmax_2) # this "show" has 1 other perf
    fixed_end = (Time.now + 1.day).change(:sec => 0)
    h = 2.5                     # hours before
    vtype = vouchertypes(:not_used_by_any_fixture)
    params = {
      :end_is_relative => "1",
      :hours_before => h.to_s,
      :addtojustone => "0",
      :valid_voucher => {
        :password => "I AM UNIQUE 2",
        :vouchertype_id => vtype.id,
        :showdate_id => sd.id.to_s,
        :max_sales_for_type => "0"
      }.merge(to_date_selects("end_sales",fixed_end)).merge(to_date_selects("start_sales",Time.now.change(:sec=>0)))
    }
    post :create, params ; assert_flash /ticket type added to all dates/i
    assert_redirected_to :controller => 'shows', :action => 'edit', :id => sd.show_id
    # verify they all got the right end date
    ValidVoucher.find_all_by_password("I AM UNIQUE 2").each do |v|
      assert_equal v.showdate.show_id, sd.show_id
      assert_equal v.showdate.thedate - h.hours, v.end_sales, " (showdate: #{sd.printable_name})"
    end
  end
end
