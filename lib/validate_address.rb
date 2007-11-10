require 'net/http'
require 'uri'
require 'rexml/document'

module ValidateAddress

  def validate_customer_address(c)
    case c.zip
    when /(\d{5}-?\d{4})/
      zip5 = Regexp.last_match(1)
      zip4 = Regexp.last_match(2)
    when /(\d{5})/
      zip5 = Regexp.last_match(1)
      zip4 = ''
    else
      zip5 = zip4 = ''
    end
    xmlstring = ''
    xm = Builder::XmlMarkup.new(:target => xmlstring)
    xm.instruct!                # add "<?xml version...>" processing instruc
    xm.AddressValidateRequest("USERID" => APP_CONFIG[:address_validation_userid])  do |z|
      z.Address() do |a|
        a.FirmName("")
        a.Address1('')
        a.Address2(c.street)
        a.City(c.city)
        a.State(c.state)
        a.Zip5(zip5)
        a.Zip4(zip4)
      end
    end
    xmlstring.slice!(0..9)
    resp = Net::HTTP.get(URI.parse(URI.escape(sprintf(APP_CONFIG[:address_validation_url], xmlstring))))
    # response successful?
    # parse XML
    cc = c.clone
    rexml = REXML::Document.new(resp).elements['AddressValidateResponse'].elements['Address']
    cc.zip = "#{rexml.get_text('Zip5')} - #{rexml.get_text('Zip4')}"
    cc.street = "#{rexml.get_text('Address2')} #{rexml.get_text('Address1')}"
  rescue
    nil
  end

  module_function :validate_customer_address

end
