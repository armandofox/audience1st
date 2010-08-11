class BulkDownload < ActiveRecord::Base
  require 'mechanize'
  serialize :report_names, Hash

  attr_accessor :report_names
  cattr_reader :vendors
  @@vendors = ['Brown Paper Tickets', 'Tix Bay Area']

  def self.create_new(args)
    args.symbolize_keys!
    klass = case args[:vendor]
            when 'Brown Paper Tickets' then BrownPaperTicketsDownload
            when 'Tix Bay Area' then TBADownload
            else raise "Don't know how to bulk download from #{type}"
            end
    return klass.send(:new, :username => args[:username], :password => args[:password])
  end

  def import_class ; raise "Must override this method in subclasses" ; end

  

end
