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
    validate_is_willcall_list
    validate_url
    self.import = GoldstarXmlImport.new
    import.xml = Nokogiri::XML::Document.parse(fetch_xml)
    raise "Malformed XML:\n#{import.xml.to_s}" unless
      import.xml.errors.empty?
  end
    
  private

  def fetch_xml(redirect_limit = 4)
    raise ArgumentError, "Too many HTTP redirects for #{@url}" if limit.zero?
    resp = Net::HTTP.get(URI.parse(@url))
    case resp
    when Net::HTTPSuccess     then @xmlcontent = resp.body
    when Net::HTTPRedirection then fetch_xml(redirect_limit - 1)
    else                      raise AutoImporter::Error, "HTTP error #{resp.code} on #{@url}"
    end
  end

  def validate_is_willcall_list
    unless email.body =~ /from the goldstar will-call system/i &&
        email['subject'].to_s =~ /will-call/i
      raise AutoImporter::Error::Ignoring, "I got an email from Goldstar, but it does not appear to be a will-call list.  So I ignored it."
    end
  end

  def validate_sender
    unless ((sender = email['from'].to_s) =~ @@from_goldstar)
      raise AutoImporter::Error::BadSender, "Email does not appear to be from Goldstar, but from #{sender}"
    end
  end

  def validate_url
    if email.body =~ @@url
      @url = Regexp.last_match(0)
    else
      raise AutoImporter::Error::MalformedEmail, "Will-call URL for XML not found"
    end
  end
  
end
