class Import < ActiveRecord::Base

  # eagerly load and declare all import types
  Dir.glob(File.join(RAILS_ROOT, 'app', 'models', '*_import.rb')).each do |importer|
    require importer
  end

  has_attachment :content_type => 'text/csv',
  :storage => :file_system,
  :max_size => 10.megabytes

  validates_as_attachment

  cattr_accessor :import_types
  @@import_types = {}

end
