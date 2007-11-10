require File.dirname(__FILE__) + '/../test_helper'

class VouchertypeTest < Test::Unit::TestCase
  fixtures :vouchertypes

  def test_001_basic
    assert_kind_of Vouchertype, vouchertypes(:single_generic_1_offerpublic)
    assert_equal 5.00, vouchertypes(:single_generic_1_offerpublic).price
    assert  !(vouchertypes(:single_generic_1_offerpublic).is_bundle? )
  end

  # a Bundle voucher should unpack into a hash
  def test_010_bundle_unmarshal
    hsh = vouchertypes(:bundle_1oftype1_3oftype2).included_vouchers
    assert hsh.has_key?(1)
    assert hsh[1] == 1
    assert hsh.has_key?(2)
    assert hsh[2] == 3
  end

  # deleting a vouchertype should delete associated vouchers
  def test_999_delete_vouchertype
    test_type = :single_generic_1_offerpublic
    id = vouchertypes(test_type).id
    vouchertypes(test_type).destroy
    assert ! Voucher.find(:first, :conditions => ['vouchertype_id = ?', id])
  end
end
