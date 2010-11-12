class GoldstarXmlImport < TicketSalesImport

  require 'nokogiri'
  attr_accessor :xml

  private
  
  def get_ticket_orders
    @xml ||= self.as_xml
    @showdate = get_showdate
    @vouchers = []
    xml.xpath("//willcall/inventories/inventory").each do |inventory|
      inventory.each_offer do |vouchertype|
      end
    end
    
  end

  def extract_date_and_time
    begin
      date = xml.xpath("//willcall/on-date").first.text 
      time = xml.xpath("//willcall/time-note").first.text 
      datetime = Time.parse "#{date} #{time}"
    rescue Exception => e
      raise TicketSalesImport::ImportError, "Can't find valid date and time in import document: #{e.message}"
    end
    datetime
  end
  
  def get_showdate
    datetime = extract_date_and_time
    showdates = Showdate.find_all_by_thedate(datetime)
    raise TicketSalesImport::ShowNotFound and return if showdates.empty?
    raise TicketSalesImport::ImportError, "Multiple matches for showdate '#{datetime}'" if showdates.length > 1
    showdates.first
  end

  def as_xml
    with_attachment_data do |fh|
      return Nokogiri::XML::Document.parse(fh)
    end
  end

end
