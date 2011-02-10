class AutoImporter

  class AutoImporter::Error < Exception ; end
  class AutoImporter::Error::Ignoring < Exception ; end
  class AutoImporter::Error::BadSender < Exception ; end
  class AutoImporter::Error::MalformedEmail < Exception ; end
  class AutoImporter::Error::HTTPError < Exception ; end
  
  class AutoImporterMailer < ActionMailer::Base
    helper :customers
    helper :popup_help
    def auto_importer_report(messages, import)
      @subject = "Audience1st AutoImporter report"
      @body = {:messages => messages, :venue => Option.value(:venue_name), :import => import}
      @recipients = Option.value(:boxoffice_daemon_notify)
      @from       = APP_CONFIG[:boxoffice_daemon_address]
      @headers    = {}
    end
  end

  attr_accessor :import, :errors, :email

  def initialize
    @errors = []
    @email = nil
    @import = nil
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
      @errors << e.message
      success = nil
    ensure
      AutoImporterMailer.deliver_auto_importer_report(all_messages, import)
      return success
    end
  end
    
  def prepare_import ; raise "Must override this method" ;  end

  def prepare_summary_messages ; end

  protected

  def all_messages
    messages = ["Importer: #{self.class}"] + @errors
    if @import
      messages << "Import type: #{@import.class}"
      messages += @import.errors.full_messages
    end
    messages.join("\n")
  end

end
