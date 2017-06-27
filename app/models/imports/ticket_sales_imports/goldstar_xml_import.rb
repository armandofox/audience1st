class GoldstarXmlImport < TicketSalesImport

  require 'nokogiri'
  attr_accessor :xml
  attr_accessor :offers
  attr_accessor :showdate
  
  private

  GOLDSTAR_VOUCHERTYPE_NAME = 'Goldstar' # Voucher types must start with this

  def show_is_part_of_import? ; true ; end
  
  def sanity_check
    offers && offers.length >= 1 && @showdate.kind_of?(Showdate)
  end

  def get_ticket_orders
    self.xml ||= self.as_xml
    @showdate = get_showdate
    self.show = @showdate.show
    @vouchers = []
    @offers = parse_offers(xml.xpath("//willcall/inventories/inventory/offers"))
    purchases =  xml.xpath("//willcall/inventories/inventory/purchases/purchase")
    purchases.each do |purchase|
      if (vouchers = ticket_order_from_purchase(purchase,@showdate))
        self.number_of_records += 1
        @vouchers += vouchers
      end
    end
    @vouchers
  end

  def parse_offers(offers_xml)
    offer_hash = {}
    raise TicketSalesImport::ImportError, "No offers found" if offers_xml.nil?
    begin
      offers_xml.xpath("//offer").each do |offer|
        id = offer.xpath("offer_id").text
        price = offer.xpath("our_price").text.to_f
        vtype = get_or_create_vouchertype(price, GOLDSTAR_VOUCHERTYPE_NAME)
        offer_hash[id.to_s] = vtype
      end
    rescue Exception => e
      raise TicketSalesImport::ImportError, "Error parsing offers: #{e.message}"
    end
    offer_hash
  end

  def ticket_order_from_purchase(purchase,showdate)
    customer_attribs = customer_attribs_from_purchase(purchase)
    customer = import_customer(customer_attribs)
    comment = comment_from_purchase(purchase)
    order_date = order_date_from_purchase(purchase)
    external_key = purchase_id(purchase)
    vouchertypes = vouchertypes_from_purchase(purchase)
    vouchers = []
    vouchertypes.each_pair do |vouchertype, qty|
      0.upto(qty-1) do |ticket_number|
        real_ext_key = external_key + sprintf("%02d%", ticket_number)
        if already_entered?(real_ext_key)
          self.existing_vouchers += 1
        else
          voucher = Voucher.new_from_vouchertype(vouchertype,
            :purchasemethod => Purchasemethod.get_type_by_name('ext'),
            :showdate => showdate,
            :comments => comment,
            :external_key => real_ext_key)
          vouchers << voucher
          customer.vouchers << voucher
        end
      end
    end
    vouchers
  end

  def vouchertypes_from_purchase(purchase)
    vtypes = {}
    purchase.xpath("claims/claim").each do |claim|
      qty = claim.xpath("quantity").text.to_i
      offer_id = claim.xpath("offer_id").text
      raise(TicketSalesImport::BadOrderFormat, "Offer id #{offer_id} doesn't appear in header") unless
        offers[offer_id]
      vtypes[ offers[offer_id] ] = qty
    end
    vtypes
  end

  def extract_date_and_time
    begin
      date = xml.xpath("//willcall/on_date").first.text 
      time = xml.xpath("//willcall/time_note").first.text 
      datetime = Time.parse "#{date} #{time}"
    rescue Exception => e
      raise TicketSalesImport::DateTimeNotFound, e.message
    end
    datetime
  end

  def purchase_id(purchase)
    begin
      purchase.xpath("purchase_id").text
    rescue
      raise TicketSalesImport::ImportError, "No purchase/order ID found for: #{purchase.to_s}"
    end
  end

  def customer_attribs_from_purchase(purchase)
    begin
      id = purchase_id(purchase) rescue "???"
      first = purchase.xpath("first_name").text
      last = purchase.xpath("last_name").text
    rescue
      raise TicketSalesImport::CustomerNameNotFound, "purchase ID #{id}"
    end
    return({:first_name => first, :last_name => last})
  end
  
  def comment_from_purchase(purchase)
    purchase.xpath("note").text rescue ''
  end

  def order_date_from_purchase(purchase)
    if (dt = purchase.xpath("created_at"))
      Time.parse(dt.text)
    else
      Time.now
    end
  end

  def get_showdate
    datetime = extract_date_and_time
    showdates = Showdate.where('thedate = ?', datetime)
    raise(TicketSalesImport::ShowNotFound, datetime.to_formatted_s) if showdates.empty?
    raise(TicketSalesImport::MultipleShowMatches, showdates.map { |s| s.printable_name }.join(', ')) if showdates.length > 1
    showdates.first
  end

end
