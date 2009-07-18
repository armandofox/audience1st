class EmailGoldstar < ActionMailer::Base
  require 'tempfile'
  require 'application.rb'
  require 'parseexcel'
  require 'generator'

  @@verbose = false
  @@error_trace = []
  @@testing = false

  def self.debug(s)
    puts(s) if @@verbose
    logger.info(s)
    @@error_trace << s
  end

  def self.error_trace
    @@error_trace.reverse.join("\n")
  end

  def self.parse_only(email,verbose=false)
    @@verbose = verbose
    offers, orders = self.prepare(email)
    if orders.nil?
      puts "No Goldstar tickets sold"
    else
      puts "Goldstar sold:\n" +
        offers.to_a.map { |x| x.join(" ")}.join("\n")
      puts orders.join("\n")
    end
  end

  def self.import(email,verbose=false)
    EmailGoldstar.process(email, verbose)
  end

  def receive(email)
    EmailGoldstar.process(email, false)
  end

  def self.process(email, verbose=false)
    @@verbose = verbose
    @@testing = ! ENV["TESTING"].blank?
    tix_added = 0
    msg = ""
    showdate = nil
    begin
      msg << "\n\n        *** TEST MODE *** NO ORDERS WILL BE ADDED ***\n\n" if @@testing
      offers, orders = self.prepare(email)
      raise "No valid ticket offers found" unless offers
      showdate = offers[offers.keys.first].showdate
      if orders.nil? || orders.empty?
        msg << "No Goldstar tickets sold for this performance\n"
      else
        msg << "Goldstar sold:\n" <<
          offers.keys.map { |k| "#{k}: #{offers[k]}" }.join("\n") <<
          "\n" << ("-" * 40) << "\n"
        tix_added = self.process_orders(orders) unless @@testing
        msg << orders.map { |o| o.to_s }.join("\n")
        if (unsold = TicketOffer.unsold(offers.values)) > 0
          msg << "\n#{unsold} tickets can be released to general inventory\n"
          # TBD add extra seats back into general inv by boosting house cap?
        end
      end
     rescue Exception => e
      msg << "** ERROR processing Goldstar report (trace follows):\n"
      msg << e.message << "\n"
      msg << self.error_trace
      if defined?(tix_added)
        msg << "\n(#{tix_added} tickets were successfully recorded)\n"
      end
      showdate = nil unless defined?(showdate)
      msg << "\n\n------#{email}\n--------\n"
    end
    debug(showdate ? showdate.printable_name : "(No showdate)")
    debug("\n" << msg)
    if @@testing
      File.open("/tmp/email_goldstar_log", "w+") { |f|  f.print msg }
    else
      deliver_goldstar_email_report(showdate,msg)
    end
  end

  def self.prepare(excel_filepath)
    debug("Trying to extract Excel attachment...")
    workbook =  extract_attachment(/\.xls$/i, excel_filepath)
    debug "#{workbook.num_rows} rows"
    rows = Generator.new(workbook.worksheet(0))
    sd = get_showdate(rows)
    debug "Showdate: #{sd}\n"
    # parse the offered ticket types and
    #  match each to a Vouchertype for this showdate.  returns a hash
    # with key=offer description and value=corresponding vouchertype object
    offers = parse_ticket_types_for_showdate(rows,sd)
    orders = parse_orders(offers,rows)
    return [offers, orders]
  end

  def self.process_orders(orders)
    tix_added = 0
    debug("Processing #{orders.length} orders")
    orders.each do |o|
      if (cust = o.process!)
        Txn.add_audit_record(:txn_type => 'tkt_purch',
                             :customer_id => cust.id,
                             :comments => "Goldstar #{o.order_key} auto-entered",
                             :logged_in_id => Customer.nobody_id)
        tix_added += o.qty
      end
    end
    tix_added
  end

  private

  def self.scan_to(rowgen, regex)
    debug "Scanning for #{regex.inspect}...\n"
    mtch = false
    while (!mtch && rowgen.next?) do
      r = rowgen.next
      mtch = starts_with(r, regex)
    end
    raise "Column header not found: '#{regex.inspect}'" unless mtch
    r
  end

  def self.starts_with(row, regex)
    row && row.at(0) && row.at(0).to_s.match(regex)
  end

  def self.parse_ticket_types_for_showdate(rows, sd)
    row = scan_to(rows, /^offer$/i )
    offers = {}
    while (row && rows.next? && !starts_with(row, /will-call/i )) do
      row = rows.next
      if row && row[0] && !(row[0].to_s.blank?)
        name = row[0].to_s
        price= row[2].to_f
        noffered = row[3].to_i
        nsold = row[4].to_i
        debug "#{name} => #{nsold}/#{noffered} @ $#{price}\n"
        # find matching vouchertype for this offer
        if nsold > 0            # otherwise not worth pursuing
          offers[name] = TicketOffer.new(sd, price, noffered, nsold, "%Goldstar%")
        end
      else
        debug "Skipping row\n"
      end
    end
    offers
  end

  def self.parse_orders(tixtypes,rows)
    tix = []
    return tix if tixtypes.empty?
    # find the "Last Name" line and consume subsequent lines until a blank
    row = scan_to(rows, /^last\s+name$/i)
    while (rows.next?) do
      row = rows.next
      if (row && !row.empty? && row[4].to_s.match( /^\d+$/ ))

        tix<< ExternalTicketOrder.new(:last_name => row[0].to_s,
                                      :first_name => row[1].to_s,
                                      :qty => row[2].to_i,
                                      :ticket_offer => tixtypes[row[3].to_s],
                                      :order_key => row[4].to_s)
      end
    end
    tix
  end

  def self.extract_attachment(filename_regexp,email)
    # check if from Goldstar
    debug("Received email from  #{email.from[0]}")
    if !@@testing && RAILS_ENV == 'production' && email.from[0] !~ /venues@goldstar/i
      raise "Bad sender"
    end
    raise "No attachments found" unless email.has_attachments?
    raise "No attachment of type #{filename_regexp.inspect} found" unless
      a = email.attachments.select { |a| a.original_filename.match(filename_regexp) }
    raise "#{a.length} attachments matching #{filename_regexp.inspect}" unless a.length==1
    t = Tempfile.new("xls")
    t.write(a.first.read)
    t.flush
    debug("File saved in #{t.path}")
    Spreadsheet::ParseExcel.parse(t.path)
  end


  def self.get_showdate(rows)
    # find the "Date/Time" line
    row = scan_to(rows, /date\/time/i )
    # find the showdate that matches this date
    Time.parse(row.at(1).to_s)
  end

  def goldstar_email_report(showdate,msg)
    sh = showdate.kind_of?(Showdate) ? showdate.printable_name : "???"
    @subject    = "GoldStar will-call processing for #{sh}"
    @body       = {
      :msg => msg,
      :showdate => sh
    }
    @recipients = Option.value(:boxoffice_daemon_notify)
    @from       = APP_CONFIG[:boxoffice_daemon_address]
    @headers    = {}
  end

end
