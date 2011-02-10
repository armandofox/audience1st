require 'date_time_extras'
require 'string_extras'

class AutoImporter < ActionMailer::Base

  attr_accessor :import, :messages, :email

  def initialize
    super
    @messages = []
    @email = nil
    @import = nil
  end


  helper :customers
  helper :popup_help

  class AutoImporter::Error < Exception ; end
  class AutoImporter::Error::Ignoring < Exception ; end
  class AutoImporter::Error::BadSender < Exception ; end
  class AutoImporter::Error::MalformedEmail < Exception ; end
  class AutoImporter::Error::HTTPError < Exception ; end
  
  def auto_importer_report(msgs, import)
    @subject = "Audience1st AutoImporter report"
    @body = {:messages => msgs, :venue => Option.value(:venue_name), :import => import}
    @recipients = Option.value(:boxoffice_daemon_notify)
    @from       = APP_CONFIG[:boxoffice_daemon_address]
    @content_type = 'text/html'
  end

  # This is the method ultimately called by script/runner, passed a TMail::Mail object
  def receive(tmail)
    @email = tmail
    self.execute!
  end

  # This constructor is more useful for testing
  def self.import_from_email(raw_email)
    obj = self.send(:new)
    obj.email = TMail::Mail.parse(raw_email)
    obj.execute!
  end

  def testing?
    nil
  end

  def execute!
    success = nil
    begin
      prepare_import
      self.testing? ? import.preview : import.import!
      prepare_summary_messages
      success = true
    rescue Exception => e
      @messages << e.message
      success = nil
    ensure
      AutoImporter.deliver_auto_importer_report(@messages, import)
      return success
    end
  end
    
  def prepare_import ; raise "Must override this method" ;  end

  def prepare_summary_messages
    @messages.unshift("Importer: #{self.class}")
    if import
      @messages << "Import type: #{@import.class}"
      @messages += import.errors.full_messages
      @messages << "Show date: #{import.showdate.printable_name}"
      @messages << "Number of tickets ADDED to will-call list: #{import.vouchers ? import.vouchers.length : 0}"
      @messages << "Number of tickets that ALREADY existed in will-call: #{import.existing_vouchers}"
    end
  end

end
