require File.dirname(__FILE__) + '/../test_helper'

class ValidVoucherTest < Test::Unit::TestCase
  fixtures :valid_vouchers, :vouchertypes, :shows, :showdates, :customers
  self.use_transactional_fixtures = true

  def setup
    @c = customers(:tom)        # tom is a subscriber
    @c2 = customers(:tom2)      # tom2 is not a subscriber
    @a = customers(:admin)      # admin is a super-admin
    @sd = showdates(:upcoming_musical_hasmax_2)
    assert_equal 0, @sd.compute_total_sales
    assert_equal 2,@sd.capacity
  end

  def look_for(s,c,vtype,qty=nil,msg=nil)
    assert_not_nil res2 = ValidVoucher.numseats_for_showdate_by_vouchertype(s,c,vtype)
    if (qty)
      assert_equal qty, res2.howmany, res2
    end
    if msg
      assert_match msg, res2.explanation, res2
    end
  end

  def assert_has_vtype(avs,vtype)
    assert avs.find { |av| av.vouchertype_id == vouchertypes(vtype).id }
  end

  def test_010_showdate_passed
    @sd.thedate = Time.now - 1.day
    res = ValidVoucher.numseats_for_showdate(@sd,@c)
    assert res.all? { |av| av.explanation.match( /date has already passed/i ) }
    res = ValidVoucher.numseats_for_showdate(@sd,@a)
    assert_equal 5, res.length, res
    assert_has_vtype res,:subscriber_only_simple
    assert_has_vtype res, :single_generic_1_offerpublic
    assert_has_vtype res, :simple
    assert_has_vtype res, :discount
    assert_has_vtype res, :free
  end

  def test_011_sold_out
    v = vouchertypes(:simple)
    reserve(@sd,v,2)
    assert_equal 2, @sd.compute_total_sales
    [@c,@a].each do |cust|
      res = ValidVoucher.numseats_for_showdate(@sd,cust)
      assert res.all? { |av| av.explanation.match( /sold out/i ) }
    end
  end

  def test_012_maxout_vouchertype
    v = vouchertypes(:single_generic_1_offerpublic)   # there's a limit of 1
    look_for(@sd,@c,v,1)
    reserve(@sd,v,1)
    look_for(@sd,@c,v,0,/none left/i)
  end

  def test_013_startdate
    v = valid_vouchers(:upcoming_musical_hasmax_2_simple)
    start_sales = Time.now + 1.day
    v.start_sales = start_sales
    v.save!
    look_for(@sd,@c,v.vouchertype,0,/go on sale/i)
    # should be ok for an admin
    look_for(@sd,@a,v.vouchertype,2)
  end

  def test_014_enddate
    v = valid_vouchers(:upcoming_musical_hasmax_2_simple)
    v.end_sales = Time.now - 1.day
    v.start_sales = Time.now - 2.days
    v.save!
    res = ValidVoucher.numseats_for_showdate(@sd,@c)
    assert_not_nil r = res.find { |av| av.vouchertype_id == v.vouchertype_id }
    assert_match /advance sales for this ticket type have ended/i, r.explanation
    assert_equal 0, r.howmany
    # should be ok for admin
    res = ValidVoucher.numseats_for_showdate(@sd,@a)
    assert_not_nil r = res.find { |av| av.vouchertype_id == v.vouchertype_id }
    assert_equal 2, r.howmany
  end

  def test_015_subscriber
    vt = vouchertypes(:subscriber_only_simple)
    def @c.is_subscriber?; true; end
    look_for(@sd,@c,vt,1)
    look_for(@sd,@c2,vt,0,/subscribers only/i)
  end
  
end
