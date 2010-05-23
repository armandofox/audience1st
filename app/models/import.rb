class Import < ActiveRecord::Base
  require 'csv'
  
  # eagerly load and declare all import types
  cattr_reader :import_types
  @@import_types ||= {}
  def self.add_import_type(name,type)
    @@import_types[name] = type
  end
  
  Dir.glob(File.join(RAILS_ROOT, 'app', 'models', '*_import.rb')).each do |importer|
    load importer
  end

  has_attachment :content_type => 'text/csv',
  :storage => :file_system,
  :max_size => 10.megabytes

  validates_as_attachment
  validate :valid_type?

  def valid_type?
    Import.import_types.values.include?(self.type)
  end
  
  def csv_rows
    begin
      CSV::Reader.create(self.uploaded_data)
    rescue Exception => e
      msg = "Opening attachment data for #{self.filename}: #{e.message}"
      errors.add_to_base(msg)
      logger.error msg
      []
    end
  end

end
