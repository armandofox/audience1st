require File.dirname(__FILE__) + '/../test_helper'

class TxnTest < Test::Unit::TestCase
  fixtures :txns
  fixtures :txn_types

  # Replace this with your real tests.
  def test_001_no_exceptions
    assert_nothing_raised { TxnType.get_type_by_name("DOES NOT EXIST") }
    assert_nothing_raised { TxnType.get_type_by_name(nil) }
    assert_nothing_raised { TxnType.get_type_by_name('') }
    assert_nothing_raised { Txn.add_audit_record() }
    assert_nothing_raised { Txn.add_audit_record(:txn_type => "NONEXISTENT") }
  end

  # test transaction searching
end
