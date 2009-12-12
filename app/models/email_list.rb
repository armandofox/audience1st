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
    return nil if settings[:wrapper] == :test
    return true if @@hominid
    @@settings[:api_key] ||= Option.value(:mailchimp_api_key)
    @@settings[:username] ||= Option.value(:mailchimp_username)
    @@settings[:password] ||= Option.value(:mailchimp_password)
    @@settings[:main_list] ||= Option.value(:mailchimp_default_list_name)
    RAILS_DEFAULT_LOGGER.warn("NOT using Mailchimp, one or more necessary options are blank")  and return nil if
      @@settings.values.any? { |s| s.blank? }
    begin
        @@hominid = Hominid.new({:username => @@settings[:username],
                                  :password => @@settings[:password],
                                  :api_key => @@settings[:api_key],
                                  :send_goodbye => false,
                                  :send_notify => false,
                                  :double_opt => false})
      @@list = @@hominid.lists.find { |l| l["name"] == @@settings[:main_list] }
      RAILS_DEFAULT_LOGGER.info "Init Mailchimp with username '#{@@settings[:username]}'"
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info "Init Mailchimp failed: <#{e.message}>"
      return false
    end
  end

  def self.subscribe(cust, email=cust.email)
    self.init_hominid || return
    msg = "Subscribing #{cust.full_name} <#{email}> to '#{@@list}'"
    begin
      @@hominid.subscribe(@@list, email,
        {:FNAME => cust.first_name, :LNAME => cust.last_name},
        'html')
      RAILS_DEFAULT_LOGGER.info msg
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info [msg,e.message].join(': ')
    end
  end

  def self.update(cust, old_email)
    self.init_hominid || return
    msg = "Changing <#{cust.old_email}> to <#{cust.email}> " <<
      "for #{cust.full_name} in  '#{@@list}'"
    begin
      @@hominid.update_member(@@list, old_email,
                            {:FNAME => cust.first_name,
                              :LNAME => cust.last_name,
                              :EMAIL => cust.email },
                            'html')
      RAILS_DEFAULT_LOGGER.info msg
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info [msg,e.message].join(': ')
    end
  end

  def self.unsubscribe(cust, email=cust.email)
    self.init_hominid || return
    msg = "Unsubscribing #{cust.full_name} <#{email}> from '#{@@list}'"
    begin
      @@hominid.unsubscribe(@@list, email)
      RAILS_DEFAULT_LOGGER.info msg
    rescue Exception => e
      RAILS_DEFAULT_LOGGER.info [msg,e.message].join(': ')
    end
  end

end
