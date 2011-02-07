class GoldstarAutoImporter < AutoImporter
  require 'net/http'
  require 'uri'
  require 'nokogiri'
  
  # Regular expression that captures XML will-call URL in message body
  @@url = /https?:\/\/www.goldstar.com\/[\w\/]+\.xml\b/
  # Who the email must be from
  @@from_goldstar = /\bvenues@goldstar.com\b/i

  attr_accessor :url, :xmlcontent
  
  def prepare_import
    validate_sender
    validate_url
    self.import = GoldstarXmlImport.new
    import.xml = Nokogiri::XML::Document.parse(fetch_xml)
    raise ArgumentError, "Malformed XML:\n#{import.xml.to_s}" unless
      import.xml.errors.empty?
  end
    
  private

  def fetch_xml(redirect_limit = 4)
    raise ArgumentError, "Too many HTTP redirects for #{@url}" if limit.zero?
    resp = Net::HTTP.get(URI.parse(@url))
    case resp
    when Net::HTTPSuccess     then @xmlcontent = resp.body
    when Net::HTTPRedirection then fetch_xml(redirect_limit - 1)
    else                      raise "HTTP error #{resp.code} on #{@url}"
    end
  end
    

  def validate_sender
    unless ((sender = email['from'].to_s) =~ @@from_goldstar)
      raise "Email does not appear to be from Goldstar, but from #{sender}"
    end
  end

  def validate_url
    if email.body =~ @@url
      @url = Regexp.last_match(0)
    else
      raise "Will-call URL for XML not found"
    end
  end
  
end
