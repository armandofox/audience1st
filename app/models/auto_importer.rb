class AutoImporter

  class AutoImporterMailer < ActionMailer::Base
    def auto_importer_error_report(messages)
      @subject = "AutoImporter ERROR"
      @body = {:messages => messages, :venue => Option.value(:venue_name)}
      @recipients = Option.value(:boxoffice_daemon_notify)
      @from       = APP_CONFIG[:boxoffice_daemon_address]
      @headers    = {}
    end    

    def auto_importer_report(messages)
      @subject = "AutoImporter ran successfully"
      @body = {:messages => messages, :venue => Option.value(:venue_name)}
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

  def self.import_from_email(raw_email)
    obj = self.class.new
    obj.email = TMail::Mail.parse(raw_email)
    obj.execute!
  end

  def self.testing?
    true
  end

  def execute!
    begin
      prepare_import
      self.testing? ? import.preview : import.import!
      AutoImporterMailer.deliver_auto_importer_report(all_messages)
      true
    rescue Exception => e
      @errors << e.message
      AutoImporterMailer.deliver_auto_importer_error_report(all_messages)
      nil
    end
  end
    
  def prepare_import
    raise "Must override this method"
  end

  protected

  def all_messages
    messages = ["Importer: #{self.class}"] + @errors
    if @import
      messages << "Import type: #{@import.class}"
      messages += @import.messages
    end
    messages.join("\n")
  end

end
