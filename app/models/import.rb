class Import < ActiveRecord::Base
  require 'csv'

  UPLOADED_FILES_PATH = File.join(RAILS_ROOT, 'tmp')

  belongs_to :completed_by, :class_name => 'Customer'
  def self.foreign_keys_to_customer ;  [:completed_by_id] ;  end

  def completed? ; !completed_at.nil? ; end

  @@import_types = {
    'Customer/mailing list' => 'CustomerImport',
    'Brown Paper Tickets sales for 1 production' => 'BrownPaperTicketsImport',
    'TBA sales list for Run of Show' => 'TBAWebtixImport'
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

  def csv_rows(fs=',')
    filename = File.join(UPLOADED_FILES_PATH, self.filename)
    filename = self.public_filename unless File.readable?(filename)
    begin
      # strip stray ^M's from DOS files
      CSV::Reader.create(IO.read(filename).gsub(/\r\n/,' '), fs)
    rescue Exception => e
      msg = "Getting attachment data for #{filename}: #{e.message}"
      errors.add_to_base(msg)
      logger.error msg
      []
    end
  end

end
