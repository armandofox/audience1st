
require File.dirname(__FILE__) + '/../test_helper'

class ShowTest < Test::Unit::TestCase
  fixtures :shows, :showdates

  def setup
  end


  def test_destroy
    @show = shows(:upcoming_musical)
    @show.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Show.find(@show.id) }
    assert_nil Showdate.find_by_show_id(@show.id)
  end
  
end
