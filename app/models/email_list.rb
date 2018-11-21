class EmailList

  # this version works with Brian Getting's Hominid gem:
  #  script/plugin install git://github.com/bgetting/hominid.git

  attr_reader :errors, :apikey, :disabled

  def initialize
    @apikey = Option.mailchimp_key
    @list = Option.mailchimp_default_list_name
    Rails.logger.info("NOT initializing mailchimp") and return nil if (@apikey.blank? || @list.blank?)
    @disabled = true
    begin
      @hominid = Hominid::Base.new :api_key => @apikey
      @listid = @hominid.find_list_id_by_name(@list)
      @disabled = false
      Rails.logger.info "Init Mailchimp with default list '#{@list}'"
    rescue NoMethodError => e   # dereference nil.[] means list not found
      Rails.logger.warn "Init Mailchimp: list '#{@list}' not found"
    rescue StandardError => e
      Rails.logger.info "Init Mailchimp failed: <#{e.message}>"
    end
  end


  private

  def segment_id_from_name(name)
    @hominid.static_segments(@listid).detect { |s| s['name'] == name }['id']
  end

  public

  def subscribe(cust, email=cust.email)
    return true if disabled
    Rails.logger.info "Subscribe #{cust.full_name} as #{email}"
    msg = "Subscribing #{cust.full_name} <#{email}> to '#{@list}'"
    begin
      @hominid.subscribe(
        @listid,
        email,
        {:FNAME => cust.first_name, :LNAME => cust.last_name},
        {:email_type => 'html'})
      Rails.logger.info msg
    rescue StandardError => e
      Rails.logger.info [msg,e.message].join(': ')
    end
  end

  def update(cust, old_email)
    return nil if @disabled
    Rails.logger.info "Update email for #{cust.full_name} from #{old_email} to #{cust.email}"
    begin
      # update existing entry
      msg = "Changing <#{old_email}> to <#{cust.email}> " <<
        "for #{cust.full_name} in  '#{@list}'"
      @hominid.update_member(
        @listid,
        old_email,
        {:FNAME => cust.first_name, :LNAME => cust.last_name,
          :email => cust.email })
    rescue Hominid::ListError => e
      if (e.message !~ /no record of/i)
        msg = "Hominid error: #{e.message}"
      else
        begin
          # was not on list previously
          msg = "Adding #{cust.email} to list #{@list}"
          @hominid.subscribe(@listid, cust.email,
            {:FNAME => cust.first_name, :LNAME => cust.last_name},
            {:email_type => 'html'})
        rescue Exception => e
          throw e
        end
      end
      # here if all went well...
      Rails.logger.info msg
    rescue Exception => e
      Rails.logger.info [msg,e.message].join(': ')
    end
  end

  def unsubscribe(cust, email=cust.email)
    return nil if @disabled
    Rails.logger.info "Unsubscribe #{cust.full_name} as #{email}"
    msg = "Unsubscribing #{cust.full_name} <#{email}> from '#{@list}'"
    begin
      @hominid.unsubscribe(@listid, email)
      Rails.logger.info msg
    rescue Exception => e
      Rails.logger.info [msg,e.message].join(': ')
    end
  end

  def create_sublist_with_customers(name, customers)
    create_sublist(name) && add_to_sublist(name, customers)
  end

  def create_sublist(name)
    return nil if @disabled
    begin
      @hominid.add_static_segment(@listid, name)
      return true
    rescue Exception => e
      error = "List segment '#{name}' could not be created: #{e.message}"
      Rails.logger.warn error
      @errors = error
      return nil
    end
  end

  def get_sublists
    # returns array of 2-element arrays, each of which is [name,count] for static segments
    return [] if @disabled
    begin
      segs = @hominid.static_segments(@listid).map { |seg| [seg['name'], seg['member_count']] }
      puts "Returning static segments: #{segs}"
      segs
    rescue Exception => e
      Rails.logger.info "Getting sublists: #{e.message}"
      []
    end
  end

  def add_to_sublist(sublist,customers=[])
    return nil if @disabled
    begin
      seg_id = segment_id_from_name(sublist)
      emails = customers.select { |c| c.valid_email_address? }.map { |c| c.email }
      if emails.empty?
        @errors = "None of the matching customers had valid email addresses."
        return 0
      end
      result = @hominid.static_segment_add_members(@listid, seg_id, emails)
      if !result['errors'].blank?
        @errors = "MailChimp was unable to add #{result['errors'].length} of the customers, usually because they aren't subscribed to the master list."
      end
      return result['success'].to_i
    rescue StandardError => e
      @errors = e.message
      Rails.logger.info "Adding #{customers.length} customers to sublist '#{sublist}': #{e.message}"
      return 0
    end
  end

end
