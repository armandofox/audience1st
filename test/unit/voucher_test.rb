require File.dirname(__FILE__) + '/../test_helper'

# Tom starts out with a single Subscription voucher that includes 1 voucher
# of type 1 and 3 of type 2, and qualifies him as a subscriber

class VoucherTest < Test::Unit::TestCase
  fixtures :vouchers, :vouchertypes, :customers, :purchasemethods, :showdates, :shows, :valid_vouchers

  self.use_transactional_fixtures = true

  def setup
    @v = customers(:tom2).vouchers
    assert_equal 0, @v.length
  end

  def refresh_tom_vouchers
    Customer.find(customers(:tom2).id).vouchers.reload
  end
  
  def test_001_regular_voucher
    Voucher.add_vouchers_for_customer(vouchertypes(:single_generic_1_offerpublic).id, 
                                      2,
                                      customers(:tom2),
                                      purchasemethods(:simple_purch).id, 
                                      0, 
                                      'Comment')
    # did it get added?
    assert_equal 2, customers(:tom2).vouchers.length
  end

  # check that adding a bundle type voucher actually adds the individual
  # vouchers that are in the bundle.  Check that deleting the bundle
  # voucher doesn't delete any regular vouchers.

  def test_010_bundle_voucher
    Voucher.add_vouchers_for_customer(vouchertypes(:bundle_1oftype1_3oftype2).id,
                                      2,
                                      customers(:tom2),
                                      purchasemethods(:simple_purch).id,
                                      0,
                                      'Comment')
    # did all 10 get added? (2 bundles of 1+3, plus the bundle vouchers themselves)
    assert_equal 10, customers(:tom2).vouchers.length
    # are types and quantities individually OK?
    type1vouchers = customers(:tom2).vouchers.find_all_by_vouchertype_id(vouchertypes(:single_generic_1_offerpublic).id)
    assert_equal 2, type1vouchers.length
    type1vouchers.each { |e| assert ! (e.vouchertype.is_bundle?) }
    type2vouchers = customers(:tom2).vouchers.find_all_by_vouchertype_id(vouchertypes(:single_generic_2_no_offerpublic).id)
    assert_equal 6, type2vouchers.length
    type2vouchers.each { |e| assert ! (e.vouchertype.is_bundle?) }
    bundles = customers(:tom2).vouchers.find_all_by_vouchertype_id(vouchertypes(:bundle_1oftype1_3oftype2).id)
    assert_equal 2, bundles.length
    bundles.each { |e| assert e.vouchertype.is_bundle? }
    # delete the bundle voucher and make sure the non-bundle ones aren't
    # deleted
    count = refresh_tom_vouchers.length
    bundles.each { |v| v.destroy }
    assert_equal count-2, refresh_tom_vouchers.length
    assert_nil refresh_tom_vouchers.detect { |v| v.vouchertype.is_bundle? }
  end

  def test_011_basic_validity
    v = Voucher.anonymous_voucher_for(showdates(:upcoming_musical_nomax).id,
                                      vouchertypes(:single_generic_1_offerpublic).id)
    assert v.valid?
  end

  def test_020_changeable
    expired_voucher = vouchers(:tom_type1)
    no_exp_date_changeable = vouchers(:tom_type2_1)
    assert expired_voucher.can_be_changed?(customers(:walkup_sales_user))
    assert !(expired_voucher.can_be_changed?(customers(:tom)))
    assert no_exp_date_changeable.can_be_changed?(customers(:tom))
    # make voucher 'unchangeable' - except by admins
    no_exp_date_unchangeable = vouchers(:tom_type2_2)
    no_exp_date_unchangeable.changeable = false
    assert !(no_exp_date_unchangeable.can_be_changed?(customers(:tom)))
    assert no_exp_date_unchangeable.can_be_changed?(customers(:walkup_sales_user))
    # if show has started, voucher is unchangeable
    no_exp_date_changeable.showdate_id = showdates(:past_musical_hasmax_1).id
    assert !(no_exp_date_changeable.can_be_changed?(customers(:tom)))
    assert no_exp_date_changeable.can_be_changed?(customers(:walkup_sales_user))
  end

  def test_030_validity
    v = vouchers(:tom_type1)
    a = v.numseats_for_showdate(showdates(:upcoming_musical_nomax), ignore_cutoff=true)
    assert !(a.available?)
    assert_match /not valid for this performance/i, a.explanation, a.explanation
    assert_equal 0, a.howmany
    a = v.numseats_for_showdate(showdates(:upcoming_musical_hasmax_2), ignore_cutoff=true)
    assert a.available?, a.explanation
    assert_equal 1, a.howmany
  end

  def test_040_reservation
    v = vouchers(:tom3_type1)
    logged_in = customers(:tom3).id
    # try reserve for invalid showdate
    sd = showdates(:past_musical_hasmax_1)
    res = v.reserve_for(sd.id,logged_in)
    assert !res
    # now try for valid showdate
    sd = showdates(:upcoming_musical_hasmax_2)
    res = v.reserve_for(sd.id,logged_in)
    assert res, v.comments
    # TBD: check auditing here?/
    # now try again, should fail
    res = v.reserve_for(sd.id,logged_in)
    assert !res
    assert_match sd.show.name, v.comments, v.comments
  end

  def test_041_cancel
    #flunk
  end
  
end
