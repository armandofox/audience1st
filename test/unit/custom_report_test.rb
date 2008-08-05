require File.dirname(__FILE__) + '/../test_helper'

class CustomReportTest < Test::Unit::TestCase
  #fixtures :custom_reports

  # Replace this with your real tests.

  def setup
    @r = CustomReport.new
  end
  
  def test_000_load
    assert CustomReport.all_clauses.kind_of?(Array)
  end

  def test_001_add_clause
    assert_nothing_raised {
      @r.add_clause(:customer_type)
    }
    assert_equal true, @r.uses_clause?(:customer_type)
    assert_equal false, @r.uses_clause?(:customer_record)
  end

  def test_002_remove_clause
    @r.add_clause(:customer_type)
    @r.remove_clause(:customer_type)
    assert_equal false, @r.uses_clause?(:customer_type)
  end

  def test_003_add_nonexistent
    assert_raise(ArgumentError) {
      @r.add_clause("Nonexistent")
    }
  end

end
