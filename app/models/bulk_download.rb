class BulkDownload < ActiveRecord::Base
  require 'mechanize'
  serialize :report_names, Hash

  validate :report_names_retrieved

  def report_names_retrieved
    errors.add(:base, "No report names could be retrieved.  Make sure your login and password are correct.") unless report_names && report_names.is_a?(Hash)
  end

  cattr_reader :vendors
  @@vendors = ['Brown Paper Tickets', 'Tix Bay Area']

  def self.create_new(args)
    args.symbolize_keys!
    klass = case args[:vendor]
            when 'Brown Paper Tickets' then BrownPaperTicketsDownload
            when 'Tix Bay Area' then TbaDownload
            else raise "Don't know how to bulk download from #{type}"
            end
    return klass.send(:new, :username => args[:username], :password => args[:password],
      :vendor => args[:vendor])
  end

  def import_class ; raise "Must override this method in subclasses" ; end

  

end
