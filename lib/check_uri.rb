class SimpleURIChecker
  require 'net/http'
  require 'uri'

  def initialize(str)
    @uri_str = str
    @errors = ActiveModel::Errors.new(self)
  end

  def check
    unless @uri_str =~ /^https?:\/\//i
      @errors.add(:base, 'URI must begin with http:// or https://')
      return false
    end
    @uri = URI(@uri_str)
    @resp = nil
    begin
      Net::HTTP.start(@uri.host, @uri.port) do |h|
        h.use_ssl = (@uri.scheme == 'https')
        @resp = h.head(@uri.path)
        @errors.add(:base, "URI cannot be loaded (server response code: #{@resp.code} (#{@resp.message})") unless @resp.code =~ /^2/
      end
    rescue Errno::ENOENT, StandardError => e
      @errors.add(:base, "Server cannot be contacted: #{e.message}")
    end
    return @errors.empty?
  end
  
end
