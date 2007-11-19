require File.dirname(__FILE__) + '/../test_helper'

class CreditCardTest < Test::Unit::TestCase
  include ActiveMerchant::Billing

  def setup
    @card = CreditCard.new
    @card.type   = "visa"
    @card.number = "4779139500118580"
    @card.month  = Time.now.month
    @card.year   = Time.now.year + 1
    @card.first_name   = "Test"
    @card.last_name   = "Mensch"
  end
  
  def test_validation
    c = CreditCard.new

    assert ! c.valid?
    assert ! c.errors.empty?
  end

  def test_valid
    assert @card.valid?
    assert @card.errors.empty?
  end
  
  def test_empty_names
    @card.first_name = ''
    @card.last_name = '' 
    
    assert !@card.valid?
    assert !@card.errors.empty?
  end
  
  def test_liberate_bogus_card
    c= CreditCard.new
    c.type = 'bogus'
    c.first_name = "Name"
    c.last_name = "Last"
    c.month  = 7
    c.year   = 2008
    c.valid?
    assert c.valid?
    c.type   = 'visa'
    assert !c.valid?
  end

  def test_invalid_card_numbers
    @card.number = nil
    assert !@card.valid?
    
    @card.number = "11112222333344ff"
    assert !@card.valid?

    @card.number = "111122223333444"
    assert !@card.valid?

    @card.number = "11112222333344444"
    assert !@card.valid?
  end
  
  def test_valid_card_number
    @card.number = "4242424242424242"
    assert @card.valid?
  end

  def test_valid_card_month
    @card.month  = Time.now.month
    @card.year   = Time.now.year
    assert @card.valid?
  end
 
  def test_edge_cases_for_valid_months
    @card.month = 13
    @card.year = Time.now.year
    assert !@card.valid?

    @card.month = 0
    @card.year = Time.now.year
    assert !@card.valid?
  end 

  def test_edge_cases_for_valid_years
    @card.year  = Time.now.year - 1
    assert !@card.valid?

    @card.year  = Time.now.year + 21
    assert !@card.valid?
  end

  def test_valid_year
    @card.year = Time.now.year + 1
    assert @card.valid?
  end

  def test_wrong_cardtype

    c = CreditCard.new({    
      "type"    => "visa",
      "number"  => "4779139500118580",
      "month"   => 10,
      "year"    => 2007,
      "first_name"    => "Tobias",
      "last_name"    => "Luetke"
    })

    assert c.valid?

    c.type = "master"
    assert !c.valid?

  end

  def test_constructor

    c = CreditCard.new({    
      "type"    => "visa",
      "number"  => "4779139500118580",
      "month"   => "10",
      "year"    => "2007",
      "first_name"    => "Tobias",
      "last_name"    => "Luetke"
    })

    assert_equal "4779139500118580", c.number
    assert_equal "10", c.month
    assert_equal "2007", c.year
    assert_equal "Tobias Luetke", c.name
    assert_equal "visa", c.type        
    c.valid?
  end

  def test_display_number
    assert_equal 'xxxxxxxxxxxx-1234', CreditCard.new('number' => '1111222233331234').display_number
    assert_equal 'xxxxxxxxxxx-1234', CreditCard.new('number' => '111222233331234').display_number
    assert_equal 'xxxxxxxxx-1234', CreditCard.new('number' => '1112223331234').display_number

    assert_equal '', CreditCard.new('number' => '').display_number
    assert_equal '123', CreditCard.new('number' => '123').display_number
    assert_equal '1234', CreditCard.new('number' => '1234').display_number
    assert_equal 'x-1234', CreditCard.new('number' => '01234').display_number
  end

  def test_format_expiry_year
    year = CreditCard::ExpiryYear.new(2005)
    assert_equal '2005', year.to_s
    assert_equal '2005', year.to_s(:default)
    assert_equal '05', year.to_s(:two_digit)
    assert_equal '2005', year.to_s(:four_digit)
  end

  def test_format_expiry_month
    month = CreditCard::ExpiryMonth.new(8) 
    assert_equal '8', month.to_s
    assert_equal '8', month.to_s(:default)
    assert_equal '08', month.to_s(:two_digit)
  end

  def test_valid_expiry_months
    assert !CreditCard::ExpiryMonth.new(-1).valid?
    1.upto(12){ |m| assert CreditCard::ExpiryMonth.new(m).valid? }
    assert !CreditCard::ExpiryMonth.new(13).valid?
  end

  def test_expired_date
    last_month = Time.now - 2.months
    date = CreditCard::ExpiryDate.new(last_month.month, last_month.year)
    assert date.expired?
  end

  def test_today_is_not_expired
    today = Time.now
    date = CreditCard::ExpiryDate.new(today.month, today.year)
    assert !date.expired?
  end

  def test_not_expired
    next_month = Time.now + 1.month
    date = CreditCard::ExpiryDate.new(next_month.month, next_month.year)
    assert !date.expired?
  end

  def test_valid_expiry_year
    0.upto(20){ |n| assert CreditCard::ExpiryYear.new(Time.now.year + n).valid? }
  end

  def test_invalid_expiry_year
    assert !CreditCard::ExpiryYear.new(-1).valid?
    assert !CreditCard::ExpiryYear.new(Time.now.year + 21).valid?
  end

  def test_type
    assert_equal 'visa', CreditCard.type?('4242424242424242')
    assert_equal 'american_express', CreditCard.type?('341111111111111')
    assert_nil CreditCard.type?('')
  end
end
