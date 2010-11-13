class GoldstarXmlImport < TicketSalesImport

  require 'nokogiri'
  attr_reader :xml
  attr_accessor :offers
  
  public

  GOLDSTAR_VOUCHERTYPE_NAME = 'Goldstar' # Voucher types must start with this

  protected
  
  def get_ticket_orders
    @xml ||= self.as_xml
    @showdate = get_showdate
    @vouchers = []
    @offers = parse_offers(xml.xpath("//willcall/inventories/inventory/offers"))
    xml.xpath("//willcall/inventories/inventory/purchases/purchase").each do |purchase|
      if (vouchers = ticket_order_from_purchase(purchase))
        self.number_of_records += 1
        @vouchers += vouchers
      end
    end
  end

  private

  def parse_offers(offers)
    offer_hash = {}
    raise TicketSalesImport::ImportError, "No offers found" if offers.nil?
    begin
      offers.xpath("//offer").each do |offer|
        id = offer.xpath("offer-id").text
        price = offer.xpath("our-price").text.to_f
        vtype = get_or_create_vouchertype(price, GOLDSTAR_VOUCHERTYPE_NAME)
        offer_hash[id.to_s] = vtype
      end
    rescue Exception => e
      raise TicketSalesImport::ImportError, "Error parsing offers: #{e.message}"
    end
    offer_hash
  end

  def ticket_order_from_purchase(purchase)
    customer_attribs = customer_attribs_from_purchase(purchase)
    customer = import_customer(customer_attribs)
    vouchertypes = vouchertypes_from_purchase(purchase)
    comment = comment_from_purchase(purchase)
    qty = qty_from_purchase(purchase)
    order_date = Time.now     # we really don't get a better estimate
    external_key = purchase_id(purchase)
    vouchers = []
    vouchertypes.each_pair do |vouchertype, qty|
      vouchers += Array.new(qty) do |ticket_number|
        Voucher.new_from_vouchertype(vouchertype,
          :showdate => showdate,
          :sold_on => order_date,
          :comments => comment,
          :external_key => external_key + sprintf("%02d", ticket_number))
      end
    end
    customer.vouchers += vouchers
    vouchers
  end

  private

  def extract_date_and_time
    begin
      date = xml.xpath("//willcall/on-date").first.text 
      time = xml.xpath("//willcall/time-note").first.text 
      datetime = Time.parse "#{date} #{time}"
    rescue Exception => e
      raise TicketSalesImport::DateTimeNotFound, e.message
    end
    datetime
  end

  def purchase_id(purchase)
    begin
      purchase.xpath("//purchase-id").text
    rescue
      raise TicketSalesImport::ImportError, "No purchase/order ID found for: #{purchase.to_s}"
    end
  end

  def customer_attribs_from_purchase(purchase)
    begin
      id = purchase_id(purchase) rescue "???"
      first = purchase.xpath("//first-name").text
      last = purchase.xpath("//last-name").text
    rescue
      raise TicketSalesImport::CustomerNameNotFound, "purchase ID #{id}"
    end
    return({:first_name => first, :last_name => last})
  end
  
  def comment_from_purchase(purchase)
    purchase.xpath("//note").text rescue ''
  end

  def get_showdate
    datetime = extract_date_and_time
    showdates = Showdate.find_all_by_thedate(datetime)
    raise TicketSalesImport::ShowNotFound if showdates.empty?
    raise(TicketSalesImport::MultipleShowMatches, showdates.map { |s| s.printable_name }.join(', ')) if showdates.length > 1
    showdates.first
  end

  def as_xml
    with_attachment_data do |fh|
      return Nokogiri::XML::Document.parse(fh)
    end
  end

end
