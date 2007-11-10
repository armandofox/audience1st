
require File.dirname(__FILE__) + '/../test_helper'

class PhplistUserTest < Test::Unit::TestCase
  #fixtures :phplist_users,:customers

  def test_000_default
    true
  end
  
  def no_test_001_find
    puts "Warning, phplist user test is stubbed out!"
    return true
    assert_equal phplist_users(:u1).id,  PhplistUser.find_by_email(phplist_users(:u1).email)
    assert_nil PhplistUser.find_by_email("NotHere@xx.com")
  end
    

end
