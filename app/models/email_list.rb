class EmailList

  # this version works with Brian Getting's Hominid gem:
  #  script/plugin install git://github.com/bgetting/hominid.git

  cattr_accessor :errors

  private

  @@hominid = nil
  @@list = nil
  @@listid = nil

  def self.members(what)
    begin
      res = @@hominid.members(@@listid, what, "2006-01-01", 0, 10000)
      RAILS_DEFAULT_LOGGER.info "Retrieved #{res.size} #{what} members of #{@@list}"
    rescue Exception => e
      res = []
      RAILS_DEFAULT_LOGGER.warn "Mailchimp error: #{e.message}"
    end
    res
  end

  public

  def self.disabled?
    defined?(DISABLE_EMAIL_LIST_INTEGRATION) && DISABLE_EMAIL_LIST_INTEGRATION
  end

  def self.enabled? ; !self.disabled? ; end

  def self.init_hominid
    RAILS_DEFAULT_LOGGER.info("NOT initializing mailchimp") and return nil if self.disabled?
    return true if @@hominid
    apikey = Option.value(:mailchimp_api_key)
    @@list = Option.value(:mailchimp_default_list_name)
    if (apikey.blank? || @@list.blank?)
      RAILS_DEFAULT_LOGGER.warn("NOT using Mailchimp, one or more necessary options are blank")
      return nil
    end
    begin
      @@hominid = Hominid::Base.new :api_key => apikey
      raise "'#{@@list}' not found" unless
        (@@listid = @@hominid.find_list_id_by_name(@@list))
      RAILS_DEFAULT_LOGGER.info "Init Mailchimp with default list '#{@@list}'"
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info "Init Mailchimp failed: <#{e.message}>"
      return nil
    end
    return true
  end

  def self.subscribe(cust, email=cust.email)
    self.init_hominid || return
    RAILS_DEFAULT_LOGGER.info "Subscribe #{cust.full_name} as #{email}"
    msg = "Subscribing #{cust.full_name} <#{email}> to '#{@@list}'"
    begin
      @@hominid.subscribe(
        @@listid,
        email,
        {:FNAME => cust.first_name, :LNAME => cust.last_name},
        {:email_type => 'html'})
      RAILS_DEFAULT_LOGGER.info msg
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info [msg,e.message].join(': ')
    end
  end

  def self.update(cust, old_email)
    self.init_hominid || return
    RAILS_DEFAULT_LOGGER.info "Update email for #{cust.full_name} from #{old_email} to #{cust.email}"
    begin
      # update existing entry
      msg = "Changing <#{old_email}> to <#{cust.email}> " <<
        "for #{cust.full_name} in  '#{@@list}'"
      @@hominid.update_member(
        @@listid,
        old_email,
        {:FNAME => cust.first_name, :LNAME => cust.last_name,
          :email => cust.email })
    rescue Hominid::ListError => e
      if (e.message !~ /no record of/i)
        msg = "Hominid error: #{e.message}"
      else
        begin
          # was not on list previously
          msg = "Adding #{cust.email} to list #{@@list}"
          @@hominid.subscribe(@@listid, cust.email,
            {:FNAME => cust.first_name, :LNAME => cust.last_name},
            {:email_type => 'html'})
        rescue Exception => e
          throw e
        end
      end
      # here if all went well...
      RAILS_DEFAULT_LOGGER.info msg
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info [msg,e.message].join(': ')
    end
  end

  def self.unsubscribe(cust, email=cust.email)
    self.init_hominid || return
    RAILS_DEFAULT_LOGGER.info "Unsubscribe #{cust.full_name} as #{email}"
    msg = "Unsubscribing #{cust.full_name} <#{email}> from '#{@@list}'"
    begin
      @@hominid.unsubscribe(@@listid, email)
      RAILS_DEFAULT_LOGGER.info msg
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info [msg,e.message].join(': ')
    end
  end

  def self.create_sublist(name)
    self.init_hominid || return
    begin
      @@hominid.add_static_segment(@@listid, name)
      return true
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info "Adding sublist '#{name}': #{e.message}"
      self.errors = "Error: sublist '#{name}' could not be created"
      return nil
    end
  end

  def self.get_sublists
    # returns array of 2-element arrays, each of which is [name,count] for static segments
    self.init_hominid || (return([]))
    begin
      segs = @@hominid.static_segments(@@listid).map { |seg| [seg['name'], seg['member_count']] }
      puts "Returning static segments: #{segs}"
      segs
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info "Getting sublists: #{e.message}"
      []
    end
  end

  def self.bulk_compare
    self.init_hominid || return
    both = []
    remote_only = []
    remote_emails = []
    self.members('subscribed').each do |mem|
      remote_emails << mem[:email]
      if (c = Customer.find_by_email(mem[:email]))
        both << c
      else
        remote_only << Customer.new(:first_name => mem[:FNAME], :last_name => mem[:LNAME],
          :email => mem[:email])
      end
    end
    local_only = Customer.find(:all,
      :conditions => ['email != ? AND e_blacklist = ?', '', false]).reject do |c|
      remote_emails.include?(c.email)
    end
    return both, remote_only, local_only
  end

  def self.remote_unsubscribes
    self.init_hominid || return
    m = (self.members('unsubscribed') + self.members('cleaned'))
    m.map { |e| Customer.find_by_email(e[:email]) }.reject(&:nil?) 
  end
  
end
