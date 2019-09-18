class SimpleURIChecker
  require 'net/http'
  require 'uri'

  attr_reader :errors, :headers
  
  def initialize(str)
    @uri_str = str
    @errors = ActiveModel::Errors.new(self)
    @headers = {}
  end

  def check(allowed_content_types: [])
    unless @uri_str =~ /^https?:\/\//i
      @errors.add(:base, 'URI must begin with http:// or https://')
      return false
    end
    @uri = URI(@uri_str)
    @response = nil
    begin
      Net::HTTP.start(@uri.host, @uri.port, :use_ssl => (@uri.scheme == 'https')) do |h|
        @response = h.head(@uri.path)
        @headers = @response.to_hash
        @errors.add(:base, "URI cannot be loaded (server response code: #{@response.code} (#{@response.message})") unless @response.code =~ /^2/
      end
      ctype = @headers['content-type']
      if ! allowed_content_types.empty? && ! (ctype.blank? || ctype.empty?)
        if (allowed_content_types & ctype).empty?
          @errors.add(:base, "URI could be retrieved, but its content type(s) #{ctype.join(', ')} don't match the allowed types #{allowed_content_types.join(', ')}")
        end
      end
    rescue Errno::ENOENT, StandardError => e
      @errors.add(:base, "Server cannot be contacted: #{e.message}")
    end
    return @errors.empty?
  end

end
