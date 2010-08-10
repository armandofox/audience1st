class Import < ActiveRecord::Base
  require 'csv'

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

  has_attachment(:storage => :file_system,
    :path_prefix => File.join(RAILS_ROOT, 'tmp', Option.value(:venue_shortname) || 'default'),
    :max_size => 10.megabytes)

  validates_as_attachment
  validate :valid_type?

  def valid_type?
    allowed_types = Import.import_types.values
    unless allowed_types.include?(self.type)
      errors.add_to_base "I don't understand what you're trying to import (possibilities are #{allowed_types.join(',')})"
    end
  end

  attr_accessor :messages
  def messages
    @messages ||= []
  end

  def csv_rows(fs=',')
    begin
      CSV::Reader.create(IO.read(self.public_filename), fs)
    rescue Exception => e
      msg = "Getting attachment data for #{self.filename}: #{e.message}"
      errors.add_to_base(msg)
      logger.error msg
      []
    end
  end

end
