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
    raw_xml = fetch_xml()
    import.xml = Nokogiri::XML::Document.parse(raw_xml)
    raise "Malformed XML:\n#{import.xml.to_s}" unless
      import.xml.errors.empty?
  end

  private

  def fetch_xml(redirect_limit = 4)
    raise AutoImporter::Error::HTTPError, "Too many HTTP redirects for #{@url}" if
      redirect_limit == 0
    resp = Net::HTTP.get_response(URI.parse(@url))
    case resp
    when Net::HTTPSuccess
      @xmlcontent = resp.body
    when Net::HTTPRedirection
      @url = resp['location']
      fetch_xml(redirect_limit - 1)
    else
      raise AutoImporter::Error::HTTPError, "Couldn't retrieve XML will-call from Goldstar:\nHTTP error #{resp.code} on #{@url} (after #{4-redirect_limit} redirects)"
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
      raise AutoImporter::Error::BadSender, "Email does not appear to be from Goldstar, but from #{sender}.  So I ignored it."
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
