require File.dirname(__FILE__) + '/../test_helper'

class ExternalTicketOrderTest < Test::Unit::TestCase
  fixtures :showdates, :vouchertypes, :valid_vouchers, :shows, :customers, :vouchers
  self.use_transactional_fixtures = true
  
  def setup
    @showdate = showdates(:upcoming_musical_hasmax_2)
    @vouchertype = vouchertypes(:single_generic_1_offerpublic)
    @match_name = "%#{@vouchertype.name}%"
    @offer = TicketOffer.new(@showdate.thedate.strftime("%c"),
                             @vouchertype.price,
                             noffered=5,
                             nsold=5,
                             @match_name)
    @tom = customers(:tom)
    @order = ExternalTicketOrder.new(:ticket_offer => @offer,
                                     :qty => 1,
                                     :last_name => @tom.last_name,
                                     :first_name => @tom.first_name)
                                     
  end

  def check_vouchers_added(qty=@order.qty)
    @tom.reload
    v = @tom.vouchers
    found_vouchers = v.select do |vc|
      vc.vouchertype.price == @order.ticket_offer.price
      vc.vouchertype == @order.ticket_offer.vouchertype
      vc.showdate == @order.ticket_offer.showdate
    end
    assert_equal qty, found_vouchers.length, @tom.vouchers.join("\n")
  end

    
  def test_001_successful_add_to_existing_cust
    @order.qty = 2
    assert_not_nil (c= @order.process!), "Message: <#{@order.status}>"
    assert_equal c.id, @tom.id
    assert_equal 2, @order.vouchers.length, "Message: <#{@order.status}>"
    check_vouchers_added(2)
  end

  def test_002_ordernum_already_exists
    # set the order_key of tom's existing type1 voucher
    key = 959595
    v = vouchers(:tom_type1)
    v.update_attribute(:external_key, key)
    @order.qty = 2
    @order.order_key = key
    assert_nil @order.process!
    assert_match Regexp.new("already entered as voucher id #{v.id}"), @order.status
    assert_equal 0, @order.vouchers.length
    check_vouchers_added(0)
  end

  def test_003_customer_not_found_but_created
    @order.last_name = 'Jones'
    @order.first_name = 'Bob'
    @order.qty = 3
    assert_not_nil (c = @order.process!)
    assert_equal c.first_name, 'Bob', c.inspect
    assert_equal c.last_name, 'Jones'
    assert_equal 3, (v = c.vouchers).length
    v.each do |vch|
      assert_equal vch.vouchertype_id, @order.ticket_offer.vouchertype.id
      assert_equal vch.showdate_id, @order.ticket_offer.showdate.id
    end
  end

  def test_005_new_customer_name_fails_validation_cant_create
    @order.last_name = 'Jones'
    @order.first_name = ''
    assert_nil (c = @order.process!)
    assert_match /validation failed/i, @order.status
  end

  def test_006_no_valid_ticket_offer
    @order.ticket_offer = ''
    exc = assert_raise(ArgumentError) {
      @order.process!
    }
    assert_match /not tagged with valid TicketOffer/i, exc.message
  end

  def test_007_verify_only
    @order.qty = 2
    assert_not_nil (c = @order.process!(:verify_only => true))
    assert_equal c.id, @tom.id
    assert_equal 0, @order.vouchers.length
    assert_equal '(not processed)', @order.status
    check_vouchers_added(0)
  end
end
