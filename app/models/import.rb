class Import < ActiveRecord::Base
  require 'csv'
  
  # eagerly load and declare all import types
  cattr_accessor :import_types
  @@import_types = {}
  Dir.glob(File.join(RAILS_ROOT, 'app', 'models', '*_import.rb')).each do |importer|
    require importer
  end

  has_attachment :content_type => 'text/csv',
  :storage => :file_system,
  :max_size => 10.megabytes

  validates_as_attachment
  validates_inclusion_of :type, :in => self.import_types.values

  def csv_rows
    begin
      CSV::Reader.create(File.open(self.filename))
    rescue Exception => e
      logger.error "Opening attachment data for #{self.filename}: #{e.message}"
      []
    end
  end

end
