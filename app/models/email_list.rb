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
    return if @@hominid
    @@settings[:api_key] ||= Option.value(:mailchimp_api_key)
    @@settings[:username] ||= Option.value(:mailchimp_username)
    @@settings[:password] ||= Option.value(:mailchimp_password)
    @@settings[:main_list] ||= Option.value(:mailchimp_default_list_name)
    begin
        @@hominid = Hominid.new({:username => @@settings[:username],
                                  :password => @@settings[:password],
                                  :api_key => @@settings[:api_key],
                                  :send_goodbye => false,
                                  :send_notify => false,
                                  :double_opt => false})
      @@list = @@hominid.lists.find { |l| l["name"] == @@settings[:main_list] }
    rescue Exception => e
      return false
    end
  end

  def self.subscribe(cust, email=cust.email)
    self.init_hominid || return
    @@hominid.subscribe(@@list, email,
                        {:FNAME => cust.first_name, :LNAME => cust.last_name},
                        'html')
  end

  def self.update(cust, old_email)
    self.init_hominid || return
    @@hominid.update_member(@@list, old_email,
                            {:FNAME => cust.first_name,
                              :LNAME => cust.last_name,
                              :EMAIL => cust.email },
                            'html')
  end

  def self.unsubscribe(cust, email=cust.email)
    self.init_hominid || return
    @@hominid.unsubscribe(@@list, email)
  end

end
