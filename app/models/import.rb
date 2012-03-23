class Import < ActiveRecord::Base
  require 'csv'
  include Comparable
  
  UPLOADED_FILES_PATH = File.join(RAILS_ROOT, 'tmp')

  belongs_to :customer
  def self.foreign_keys_to_customer ;  [:customer_id] ;  end

  def <=>(other)
    (self.completed_at || self.updated_at || self.created_at || Time.now) <=>
      (other.completed_at || other.updated_at || other.created_at || Time.now)
  end
  
  def self.all_by_date
    Import.all.sort.reverse
  end

  def import! ; raise "Must override this method" ; end

  def finalize(bywhom = Customer.boxoffice_daemon)
    self.update_attributes(:completed_at => Time.now, :customer => bywhom)
  end

  def completed? ; !completed_at.nil? ; end

  @@import_types = {
    'Customer/mailing list' => 'CustomerImport',
    'Brown Paper Tickets sales for 1 production' => 'BrownPaperTicketsImport',
    'TBA sales list for Run of Show' => 'TbaWebtixImport',
    'Goldstar sales for one performance (CSV format)' => 'GoldstarCsvImport',
    'Goldstar sales for one performance (XML format)' => 'GoldstarXmlImport'
    }
  cattr_accessor :import_types
  def humanize_type
    @@import_types.index(self.type.to_s)
  end

  has_attachment(
    :storage => :file_system,
    :path_prefix => UPLOADED_FILES_PATH,
    :max_size => 10.megabytes)

  #validates_as_attachment
  validate :valid_type?

  def valid_type?
    allowed_types = Import.import_types.values
    unless allowed_types.include?(self.type.to_s)
      errors.add_to_base "I don't understand how to import '#{self.type}' (possibilities are #{allowed_types.join(',')})"
    end
  end

  attr_accessor :messages
  def messages
    @messages ||= []
  end

  # allow already-downloaded file to serve as attachment data for a has_attachment model
  def set_source_data(data,content_type='application/octet-stream')
    length = 0
    full_filename = short_filename = ''
    f = File.new(File.join(UPLOADED_FILES_PATH,"upload_#{Time.now.usec}"),"w+",0600)
    full_filename = f.path
    short_filename = full_filename.split('/').last
    length = f.write(data)
    logger.info "Wrote #{length} of #{data.size} bytes to #{full_filename}"
    logger.info data
    f.close
    io = open(full_filename)
    (class << io; self; end;).class_eval do
      define_method(:original_filename) { short_filename }
      define_method(:content_type) { content_type }
      define_method(:size) { length }
    end
    self.uploaded_data = io
    self.filename = short_filename
  end

  def attachment_filename
    fn = File.join(UPLOADED_FILES_PATH, self.filename.to_s)
    fn = self.public_filename unless File.readable?(fn) && !File.directory?(fn)
    fn
  end
  
  def with_attachment_data
    fn = self.attachment_filename
    begin
      fh = File.open(fn)
      yield fh
    rescue Exception => e
      msg = "Getting/parsing attachment data for #{fn}: #{e.message}"
      self.errors.add_to_base(msg)
      logger.error msg
      []
    end
  end

  def as_xml
    with_attachment_data do |fh|
      return Nokogiri::XML::Document.parse(fh)
    end
  end

end
