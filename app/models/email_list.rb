class EmailList

  # this version works with Brian Getting's Hominid gem:
  #  script/plugin install git://github.com/bgetting/hominid.git

  @@settings = {}
  @@hominid = nil
  @@list = nil
  
  def self.mode=(args={:wrapper=>:test})
    @@settings.merge!(args)
  end

  def self.init_hominid
    return nil if @@settings[:wrapper] == :test
    return true if @@hominid
    apikey = Option.value(:mailchimp_api_key)
    list = Option.value(:mailchimp_default_list_name)
    if (apikey.blank? || list.blank?)
      RAILS_DEFAULT_LOGGER.warn("NOT using Mailchimp, one or more necessary options are blank")
      return nil
    end
    begin
      @@hominid = Hominid::Base.new :api_key => apikey
      raise "'#{list}' not found" unless
        (listid = @@hominid.find_list_id_by_name(list))
      RAILS_DEFAULT_LOGGER.info "Init Mailchimp with default list '#{list}'"
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info "Init Mailchimp failed: <#{e.message}>"
      return nil
    end
    return true
  end

  def self.subscribe(cust, email=cust.email)
    self.init_hominid || return
    RAILS_DEFAULT_LOGGER.info "Subscribe #{cust.full_name} as #{email}"
    list = Option.value(:mailchimp_default_list_name)
    listid = @@hominid.find_list_id_by_name(list)
    msg = "Subscribing #{cust.full_name} <#{email}> to '#{list}'"
    begin
      @@hominid.subscribe(
        listid,
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
    list = Option.value(:mailchimp_default_list_name)
    listid = @@hominid.find_list_id_by_name(list)
    begin
      # update existing entry
      msg = "Changing <#{old_email}> to <#{cust.email}> " <<
        "for #{cust.full_name} in  '#{list}'"
      @@hominid.update_member(
        listid,
        old_email,
        {:FNAME => cust.first_name, :LNAME => cust.last_name,
          :email => cust.email })
    rescue Hominid::ListError => e
      if (e.message !~ /no record of/i)
        msg = "Hominid error: #{e.message}"
      else
        begin
          # was not on list previously
          msg = "Adding #{cust.email} to list #{list}"
          @@hominid.subscribe(listid, cust.email,
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
    list = Option.value(:mailchimp_default_list_name)
    listid = @@hominid.find_list_id_by_name(list)
    msg = "Unsubscribing #{cust.full_name} <#{email}> from '#{list}'"
    begin
      @@hominid.unsubscribe(listid, email)
      RAILS_DEFAULT_LOGGER.info msg
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info [msg,e.message].join(': ')
    end
  end

end
