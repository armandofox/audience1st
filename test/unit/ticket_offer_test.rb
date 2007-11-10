require File.dirname(__FILE__) + '/../test_helper'

class TicketOfferTest < Test::Unit::TestCase
  fixtures :showdates, :vouchertypes, :valid_vouchers, :shows
  
  def setup
    # an example existing showdate
    @s = showdates(:upcoming_musical_hasmax_2)
    # a vouchertype that is known to be valid for this showdate
    # (mapped by valid_vouchers.yml)
    @sv = vouchertypes(:single_generic_1_offerpublic)
    @match_name = "%#{@sv.name}%"
  end
  
  # Replace this with your real tests.
  def test_001_create_valid
    assert_nothing_raised do
      o = TicketOffer.new(@s.thedate.strftime("%c"),
                          @sv.price,
                          noffered = 5,
                          nsold = 5,
                          @match_name
                          )
      assert_equal @s.thedate, o.showdate.thedate
      assert_equal @sv.price, o.price
      assert_equal @sv, o.vouchertype
    end
  end

  def test_002_bad_date
    exc = assert_raise(TicketOffer::NoPerfMatch) {
      o = TicketOffer.new("not a date", @sv.price, 5, 5, @match_name)
    }
    assert_match /Found 0 performances/, exc.message
  end

  def test_003_no_voucher_at_price
    exc = assert_raise(TicketOffer::NoVoucherMatch) {
      o = TicketOffer.new(@s.thedate, 99.99, 5, 5, @match_name)
    }
    assert_match Regexp.new("^Found 0 .*'#{@match_name}'"), exc.message
  end

  def test_004_negative_number_sold
    exc = assert_raise(ArgumentError) {
      o = TicketOffer.new(@s.thedate, @sv.price, -1, 0, @match_name)
    }
    assert_match /Number offered and sold must be >= 0/, exc.message
  end

  def test_005_vouchertype_name_doesnt_match
    bad_name = "%NoMatchName%"
    exc = assert_raise(TicketOffer::NoVoucherMatch) {
      o = TicketOffer.new(@s.thedate, @sv.price, 0,0, bad_name)
    }
    assert_match Regexp.new("^Found 0 .*'#{bad_name}'"), exc.message
  end
end
