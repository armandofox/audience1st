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

    @@hominid = Hominid.new({:username => @@settings[:username],
                              :password => @@settings[:password],
                              :api_key => @@settings[:api_key],
                              :send_goodbye => false,
                              :send_notify => false,
                              :double_opt => false})
    @@list = @@hominid.lists.find { |l| l["name"] == @@settings[:main_list] }
  end

  def self.subscribe(cust)
    self.init_hominid
    @@hominid.subscribe(@@list, cust.email_when_loaded,
                        {:FNAME => cust.first_name, :LNAME => cust.last_name},
                        'html')
  end

  def self.unsubscribe(cust)
    self.init_hominid
    @@hominid.unsubscribe(@@list, cust.email_when_loaded)
  end

end
