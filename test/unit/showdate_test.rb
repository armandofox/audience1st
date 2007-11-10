require File.dirname(__FILE__) + '/../test_helper'

class ShowdateTest < Test::Unit::TestCase
  fixtures :showdates

  # Replace this with your real tests.
  def test_destroy
    @showdate = showdates(:upcoming_musical_hasmax_2)
    @showdate.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Showdate.find(@showdate.id) }
    assert_nil ValidVoucher.find_by_showdate_id(@showdate.id)
  end
end
